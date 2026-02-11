# Terraform aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfd='terraform destroy'
alias tfo='terraform output -json'

# Terraform functions

# Plan Terraform with a variable file
# Usage: tfp [filename]
# Defaults: filename=terraform.dev

function tfp() {
  local filename="${1:-terraform.dev}"
  local varfile="${filename}.tfvars"

  if [[ ! -f "$varfile" ]]; then
    echo "Error: Variable file '$varfile' not found" >&2
    return 1
  fi

  echo "Planning Terraform with variable file: $varfile"
  terraform plan -var-file="$varfile" -out=cli.tfplan
}

# Apply Terraform with a variable file or plan file
# Usage: tfa [filename]
# Defaults: filename=terraform.dev

function tfa() {
  if [[ -f "cli.tfplan" ]]; then
    echo "Applying Terraform using existing plan file: cli.tfplan"
    terraform apply cli.tfplan
  else
    local filename="${1:-terraform.dev}"
    local varfile="${filename}.tfvars"

    if [[ ! -f "$varfile" ]]; then
      echo "Error: Variable file '$varfile' not found" >&2
      return 1
    fi

    echo "Applying Terraform with variable file: $varfile"
    terraform apply -var-file="$varfile"
  fi
}
