#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

#######################################
# Config
#######################################
CLUSTER_NAME="${CLUSTER_NAME:-spot-eks-lab-babajide}"
AWS_REGION="${AWS_REGION:-us-east-1}"
NAMESPACE="${NAMESPACE:-kube-system}"
MY_NAME="${MY_NAME:-babajide}"

# Everything gets MY_NAME suffix
CONTROLLER_NAME="${CONTROLLER_NAME:-aws-load-balancer-controller-${MY_NAME}}"
SA_NAME="${SA_NAME:-aws-load-balancer-controller-${MY_NAME}}"
ROLE_NAME="${ROLE_NAME:-AmazonEKSLoadBalancerControllerRole-${MY_NAME}}"
POLICY_NAME="${POLICY_NAME:-AWSLoadBalancerControllerIAMPolicy-${MY_NAME}}"
ADDITIONAL_POLICY_NAME="${ADDITIONAL_POLICY_NAME:-AWSLoadBalancerControllerAdditionalPermissions-${MY_NAME}}"



SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="${ROOT_DIR}/infra"
POLICIES_DIR="${POLICIES_DIR:-$INFRA_DIR/policies}"
POLICY_FILE="$POLICIES_DIR/iam_policy.json"

POLICY_URL="${POLICY_URL:-https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.8.2/docs/install/iam_policy.json}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

CHART_REPO_NAME="eks"
CHART_REPO_URL="https://aws.github.io/eks-charts"
CHART_NAME="eks/aws-load-balancer-controller"

#######################################
# Logging
#######################################
info()  { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*" >&2; }
error() { echo "[ERROR] $*" >&2; }
step()  { echo; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "[STEP]  $*"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

trap 'error "Command failed on line $LINENO: $BASH_COMMAND"' ERR

#######################################
# Requirements
#######################################
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    error "Required command not found: $1"
    exit 1
  }
}

check_requirements() {
  require_cmd aws
  require_cmd kubectl
  require_cmd helm
  require_cmd eksctl
  require_cmd curl
}

#######################################
# Helpers
#######################################
update_kubeconfig() {
  step "Updating kubeconfig for cluster: ${CLUSTER_NAME}"
  aws eks update-kubeconfig \
    --region "$AWS_REGION" \
    --name "$CLUSTER_NAME"
}

ensure_cache_dir() {
  mkdir -p "$POLICIES_DIR"
}

ensure_policy_file() {
  step "Checking local IAM policy file cache"

  if [[ -f "$POLICY_FILE" ]]; then
    info "Using cached policy file: $POLICY_FILE"
    return 0
  fi

  info "Policy file not found locally, downloading it..."
  curl -fsSL "$POLICY_URL" -o "$POLICY_FILE"
  info "Downloaded policy file to: $POLICY_FILE"
}

ensure_iam_policy() {
  step "Ensuring IAM policy exists: ${POLICY_NAME}"

  if aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
    info "IAM policy already exists: $POLICY_ARN"
    return 0
  fi

  ensure_policy_file

  info "Creating IAM policy: ${POLICY_NAME}"
  aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document "file://$POLICY_FILE" >/dev/null

  info "Created IAM policy: $POLICY_ARN"
}

# Attach the missing permissions as an inline policy to the IAM role
ensure_additional_permissions_policy() {
  step "Ensuring additional permissions are attached to IAM role"

  aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "$ADDITIONAL_POLICY_NAME" \
    --policy-document '{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "elasticloadbalancing:DescribeListenerAttributes",
            "elasticloadbalancing:ModifyListenerAttributes"
          ],
          "Resource": "*"
        }
      ]
    }'

  info "Attached inline policy ${ADDITIONAL_POLICY_NAME} to role ${ROLE_NAME}"
}

oidc_provider_exists() {
  local issuer_url="$1"
  local issuer_no_https="${issuer_url#https://}"

  while read -r arn; do
    [[ -z "${arn:-}" ]] && continue

    local url
    url="$(aws iam get-open-id-connect-provider \
      --open-id-connect-provider-arn "$arn" \
      --query 'Url' \
      --output text 2>/dev/null || true)"

    if [[ "$url" == "$issuer_url" || "$url" == "$issuer_no_https" ]]; then
      return 0
    fi
  done < <(aws iam list-open-id-connect-providers \
            --query 'OpenIDConnectProviderList[].Arn' \
            --output text | tr '\t' '\n' || true)

  return 1
}

ensure_oidc_provider() {
  step "Ensuring OIDC provider exists"

  local issuer_url
  issuer_url="$(aws eks describe-cluster \
    --name "$CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --query 'cluster.identity.oidc.issuer' \
    --output text)"

  if [[ -z "$issuer_url" || "$issuer_url" == "None" ]]; then
    error "Could not determine the OIDC issuer URL for the cluster"
    exit 1
  fi

  if oidc_provider_exists "$issuer_url"; then
    info "OIDC provider already exists for issuer: $issuer_url"
    return 0
  fi

  info "OIDC provider not found. Associating it now..."
  eksctl utils associate-iam-oidc-provider \
    --cluster "$CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --approve

  info "OIDC provider associated."
}

ensure_service_account_and_role() {
  step "Ensuring IAM service account + role exist"

  local role_exists="false"
  if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    role_exists="true"
    info "IAM role already exists: $ROLE_ARN"
  fi

  if [[ "$role_exists" == "true" ]]; then
    if ! kubectl get sa "$SA_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
      info "Service account not found, creating it..."
      kubectl create sa "$SA_NAME" -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    else
      info "Service account already exists: $NAMESPACE/$SA_NAME"
    fi

    current_role_arn="$(kubectl get sa "$SA_NAME" -n "$NAMESPACE" \
      -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}' 2>/dev/null || true)"

    if [[ "$current_role_arn" != "$ROLE_ARN" ]]; then
      info "Annotating service account with IAM role ARN"
      kubectl annotate sa "$SA_NAME" -n "$NAMESPACE" \
        eks.amazonaws.com/role-arn="$ROLE_ARN" \
        --overwrite
    else
      info "Service account already annotated correctly"
    fi

    if aws iam list-attached-role-policies \
      --role-name "$ROLE_NAME" \
      --query "AttachedPolicies[].PolicyArn" \
      --output text | tr '\t' '\n' | grep -Fxq "$POLICY_ARN"; then
      info "Managed policy already attached to role"
    else
      info "Attaching managed policy to existing IAM role"
      aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "$POLICY_ARN"
    fi

    return 0
  fi

  info "Role not found. Creating IAM service account and role via eksctl..."
  eksctl create iamserviceaccount \
    --cluster "$CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --namespace "$NAMESPACE" \
    --name "$SA_NAME" \
    --role-name "$ROLE_NAME" \
    --attach-policy-arn "$POLICY_ARN" \
    --override-existing-serviceaccounts \
    --approve

  info "Created IAM service account and role."
}

ensure_helm_repo() {
  step "Ensuring Helm repo exists"

  if helm repo list | awk '{print $1}' | grep -qx "$CHART_REPO_NAME"; then
    info "Helm repo already exists: $CHART_REPO_NAME"
  else
    info "Adding Helm repo: $CHART_REPO_NAME"
    helm repo add "$CHART_REPO_NAME" "$CHART_REPO_URL"
  fi

  helm repo update >/dev/null
}

ensure_controller_release() {
  step "Ensuring AWS Load Balancer Controller Helm release exists"

  if helm status "$CONTROLLER_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
    info "Helm release already installed: $CONTROLLER_NAME"
    return 0
  fi

  info "Installing AWS Load Balancer Controller..."
  helm upgrade --install "$CONTROLLER_NAME" "$CHART_NAME" \
    -n "$NAMESPACE" \
    --set fullnameOverride="$CONTROLLER_NAME" \
    --set clusterName="$CLUSTER_NAME" \
    --set serviceAccount.create=false \
    --set serviceAccount.name="$SA_NAME" \
    --set region="$AWS_REGION" \
    --set vpcId="$(aws eks describe-cluster \
      --name "$CLUSTER_NAME" \
      --region "$AWS_REGION" \
      --query 'cluster.resourcesVpcConfig.vpcId' \
      --output text)"

  info "Helm release installed successfully."
}

wait_for_controller() {
  step "Waiting for controller deployment to be ready"

  kubectl rollout status deployment/"$CONTROLLER_NAME" \
    -n "$NAMESPACE" \
    --timeout=300s
}

verify_controller() {
  step "Verifying installation"

  kubectl get pods -n "$NAMESPACE" | grep -i load-balancer || true
  kubectl get deployment -n "$NAMESPACE" "$CONTROLLER_NAME" || true
  kubectl get sa -n "$NAMESPACE" "$SA_NAME" || true
  kubectl get ingressclass alb -o yaml || true
}

#######################################
# Main
#######################################
main() {
  check_requirements
  ensure_cache_dir
  update_kubeconfig

  ensure_iam_policy
  ensure_oidc_provider
  ensure_service_account_and_role

  # Attach the missing permissions here
  ensure_additional_permissions_policy

  ensure_helm_repo
  ensure_controller_release
  wait_for_controller
  verify_controller

  step "Done"
  info "AWS Load Balancer Controller is installed and ready."
  info "Re-check your ingress:"
  info "  kubectl get ingress -n $NAMESPACE"
  info "The ADDRESS field should populate shortly."
}

main "$@"
