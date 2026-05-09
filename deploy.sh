#!/usr/bin/env bash
#
# deploy.sh - Terraform deployment script for AWS infrastructure
# Features:
# - Strict bash safety
# - Secure .env loading
# - Structured logging
# - Dependency validation
# - Cleanup handling
# - Safer Terraform execution
# - Idempotent backend configuration
# - No unsafe export/xargs parsing
# - Better error visibility
#

set -Eeuo pipefail
IFS=$'\n\t'

#######################################
# Globals
#######################################
readonly SCRIPT_NAME="$(basename "$0")"
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BOOTSTRAP_DIR="${ROOT_DIR}/infra/terraform-bootstrap"
readonly TERRAFORM_DIR="${ROOT_DIR}/infra/terraform"
readonly BACKEND_JSON="${ROOT_DIR}/infra/terraform/backend.json"
readonly BACKEND_TF="${ROOT_DIR}/infra/terraform/backend.tf"


#######################################
# Logging
#######################################
log() {
  local level="$1"
  shift
  printf '[%s] [%s] %s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" \
    "$level" \
    "$*"
}

info() {
  log INFO "$@"
}

warn() {
  log WARN "$@" >&2
}

error() {
  log ERROR "$@" >&2
}


#######################################
# Error handling
#######################################
cleanup() {
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    error "Deployment failed with exit code: ${exit_code}"
  fi

  exit "$exit_code"
}

trap cleanup EXIT


#######################################
# Validate required commands
#######################################
require_command() {
  local cmd="$1"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "Required command not found: ${cmd}"
    exit 1
  fi
}


#######################################
# Secure .env loading
#######################################
load_env() {
  local env_file="${ROOT_DIR}/.env"

  if [[ ! -f "$env_file" ]]; then
    warn ".env file not found. Continuing with existing environment variables."
    return
  fi

  info "Loading environment variables from .env"

  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
}


#######################################
# Terraform wrapper
#######################################
terraform_run() {
  info "Running: terraform $*"

  terraform "$@"
}


#######################################
# Terraform workflow
#######################################
terraform_deploy() {
  local dir="$1"

  info "Deploying Terraform in: ${dir}"

  terraform -chdir="$dir" init -input=false

  terraform -chdir="$dir" fmt -check -recursive

  terraform -chdir="$dir" validate

  terraform -chdir="$dir" plan \
    -input=false \
    -out=tfplan

  terraform -chdir="$dir" apply \
    -input=false \
    -auto-approve \
    tfplan

  rm -f "${dir}/tfplan"
}


#######################################
# Generate backend config
#######################################
generate_backend_config() {
  local bucket_name
  local bucket_region
  local dynamodb_table_name

  bucket_name="$(jq -r '.bucket_name.value' "$BACKEND_JSON")"
  bucket_region="$(jq -r '.bucket_region.value' "$BACKEND_JSON")"
  dynamodb_table_name="$(jq -r '.dynamodb_table_name.value' "$BACKEND_JSON")"

  if [[ -z "$bucket_name" || "$bucket_name" == "null" ]]; then
    error "Failed to retrieve bucket_name from backend.json"
    exit 1
  fi

  if [[ -z "$bucket_region" || "$bucket_region" == "null" ]]; then
    error "Failed to retrieve bucket_region from backend.json"
    exit 1
  fi

  info "Generating Terraform backend configuration"

  cat > "$BACKEND_TF" <<EOF
terraform {
  backend "s3" {
    bucket = "${bucket_name}"
    key    = "terraform.tfstate"
    region = "${bucket_region}"
    dynamodb_table = "${dynamodb_table_name}"
    encrypt        = true
    use_lockfile = true
  }
}
EOF
}


#######################################
# Main
#######################################
main() {
  require_command terraform
  require_command jq

  load_env

  ###################################
  # Bootstrap S3 backend
  ###################################

  info "Starting Terraform bootstrap deployment"

  terraform_deploy "$BOOTSTRAP_DIR"

  info "Exporting Terraform outputs"

  mkdir -p "$(dirname "$BACKEND_JSON")"

  terraform -chdir="$BOOTSTRAP_DIR" output -json > "$BACKEND_JSON"

  generate_backend_config

  info "Terraform bootstrap completed"

  ###################################
  # Main infrastructure deployment
  ###################################

  info "Starting main Terraform deployment"

  terraform_deploy "$TERRAFORM_DIR"

  info "✅ Infrastructure deployment completed successfully 🚀🚀🚀"
}

main "$@"
