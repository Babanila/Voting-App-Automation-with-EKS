#!/usr/bin/env bash
#
# deploy.sh - Deploy voting app to EKS in order
#

set -Eeuo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'


info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

K8S_DIR="${ROOT_DIR}/infra/k8s"
TERRAFORM_DIR="${ROOT_DIR}/infra/terraform"


AWS_REGION="us-east-1"
NAMESPACE="babs-app"
NAME="babajide"


ensure_alb_controller() {
  if kubectl get deployment -n kube-system aws-load-balancer-controller >/dev/null 2>&1; then
    info "AWS Load Balancer Controller already exists, skipping install"
    
    # Optional: wait until it's ready
    kubectl rollout status deployment/aws-load-balancer-controller \
      -n kube-system \
      --timeout=300s
  else
    info "AWS Load Balancer Controller not found. Installing..."
    bash "${SCRIPT_DIR}/install-alb-controller.sh"
  fi
}


# ============================================
# Set Cluster & Update kubeconfig
# ============================================
info "Getting and Setting cluster name..."
CLUSTER_NAME=$(aws eks list-clusters --query "clusters[?contains(@, 'babajide')]" --output text)

info "Updating kubeconfig..."
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION


# ============================================
# Step 1: Create Namespace
# ============================================
info "Step 1: Creating namespace..."
kubectl apply -f "${K8S_DIR}/namespace.yaml"
kubectl config set-context --current --namespace=$NAMESPACE

# ============================================
# Step 2: Deploy Database Tier (Postgres only)
# ============================================
info "Step 2: Deploying Database tier (Postgres)..."

kubectl apply -f "${K8S_DIR}/database/postgres-secret.yaml"
kubectl apply -f "${K8S_DIR}/database/postgres-deployment.yaml"
kubectl apply -f "${K8S_DIR}/database/postgres-service.yaml"

info "Waiting for Postgres to be ready..."
kubectl rollout status deployment/postgres -n "$NAMESPACE" --timeout=120s

success "Database tier deployed!"

# ============================================
# Step 3: Deploy Backend Tier (Redis + Worker)
# ============================================
info "Step 3: Deploying Backend tier (Redis + Worker)..."

kubectl apply -f "${K8S_DIR}/backend/redis-deployment.yaml"
kubectl apply -f "${K8S_DIR}/backend/redis-service.yaml"
kubectl apply -f "${K8S_DIR}/backend/worker-deployment.yaml"

info "Waiting for Redis to be ready..."
kubectl rollout status deployment/redis -n "$NAMESPACE" --timeout=120s

info "Waiting for Worker to be ready..."
kubectl rollout status deployment/worker -n "$NAMESPACE" --timeout=120s

success "Backend tier deployed!"

# ============================================
# Step 4: Deploy Frontend Tier (Vote + Result)
# ============================================
info "Step 4: Deploying Frontend tier (Vote + Result)..."

kubectl apply -f "${K8S_DIR}/frontend/vote-deployment.yaml"
kubectl apply -f "${K8S_DIR}/frontend/vote-service.yaml"
kubectl apply -f "${K8S_DIR}/frontend/result-deployment.yaml"
kubectl apply -f "${K8S_DIR}/frontend/result-service.yaml"

info "Waiting for Vote to be ready..."
kubectl rollout status deployment/vote -n "$NAMESPACE" --timeout=120s

info "Waiting for Result to be ready..."
kubectl rollout status deployment/result -n "$NAMESPACE" --timeout=120s

success "Frontend tier deployed!"

# ============================================
# Step 5: Deploy Load Balancer
# ============================================
info "Step 5: Setting up Load Balancer..."
ensure_alb_controller

success "Load Balancer Configured!"

# ============================================
# Step 6: Deploy Ingress
# ============================================
if [[ -f "${K8S_DIR}/ingress.yaml" ]]; then
  info "Step 6: Deploying Ingress..."
  kubectl apply -f "${K8S_DIR}/ingress.yaml"
  success "Ingress deployed!"
fi


# ============================================
# Show Status
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


echo ""
echo "📦 Pods:"
kubectl get pods -n "$NAMESPACE" -o wide

echo ""
echo "🔗 Services:"
kubectl get svc -n "$NAMESPACE"

echo ""
echo "🌐 Ingress:"
kubectl get ingress -n "$NAMESPACE" 2>/dev/null || echo "No ingress configured"

# Get Load Balancer URL
ALB_HOST=$(kubectl get ingress voting-app-ingress -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
if [[ -n "$ALB_HOST" ]]; then
  echo ""
  echo "🌍 Vote URL: http://$ALB_HOST (or vote.babs.ironlabs.online)"
  echo "🌍 Result URL: http://result.babs.ironlabs.online"
fi

# NodePort access (if Minikube or without ALB)
echo ""
echo "📍 NodePort Access (if using Minikube):"
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "<MINIKUBE_IP>")
echo "   Vote:   http://$MINIKUBE_IP:30080"
echo "   Result: http://$MINIKUBE_IP:30081"
