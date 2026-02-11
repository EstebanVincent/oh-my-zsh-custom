# Azure aliases
alias azl='az login'

# Azure functions

# Pull secrets from Azure Key Vault and export them to an env file
# Need to be logged in to Azure CLI with permissions to access the Key Vault
# Usage: kv2env <key_vault_name> [env_file]

function kv2env() {
  local kv_name="$1"
  local env_file="${2:-$kv_name.env}"
  local script_path="/Users/esvi/Library/CloudStorage/OneDrive-Professional/Chanel/DevOps/LabCh/Common/scripts/azure/kv_secrets_to_env.py"
  local venv_path="$HOME/PythonVenvs/cha-common-scripts"

  if [[ -z "$kv_name" ]]; then
    echo "Usage: kv2env <key_vault_name> [env_file]"
    return 1
  fi

  echo "Activating venv at $venv_path"
  source "$venv_path/bin/activate"

  echo "Exporting secrets from Key Vault: $kv_name → $env_file"
  python3.12 "$script_path" -n "$kv_name" -e "$env_file"

  echo "Deactivating venv"
  deactivate
}
