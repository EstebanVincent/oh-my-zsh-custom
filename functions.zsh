# Fuzzy search with zle
# This setup enhances command history search by:
# 1. Using fzf to provide interactive fuzzy searching through command history
# 2. Binding Ctrl+R to trigger the fuzzy search
# 3. Configuring zle (Zsh Line Editor) to integrate the search results with the current command line
# 4. Setting options to display search results with syntax highlighting
function fuzzysearch() {
  BUFFER=$(history | fzf --tac --reverse | sed -E 's/^ *[0-9]+ +[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} +//')
  CURSOR=$#BUFFER
  zle redisplay
}
zle -N fuzzysearch
bindkey '^R' fuzzysearch

function pushup() {
  local remote="${1:-origin}"
  git push --set-upstream "$remote" "$(git_current_branch)" --verbose
}

function rbin() {
  local source_branch="$(git_current_branch)"
  local target_branch="${1:-develop}"
  local remote="${2:-origin}"

  git checkout "$target_branch" &&
  git pull "$remote" "$target_branch" --rebase --autostash --verbose &&
  git rebase "$source_branch" --verbose
}

function rbinup() {
  local source_branch="$(git_current_branch)"
  local target_branch="${1:-develop}"
  local remote="${2:-origin}"

  git checkout "$target_branch" &&
  git pull "$remote" "$target_branch" --rebase --autostash --verbose &&
  git rebase "$source_branch" --verbose
  pushup "$remote"
}

function mrin() {
  local source_branch="$(git_current_branch)"
  local target_branch="${1:-develop}"
  local remote="${2:-origin}"

  git checkout "$target_branch" &&
  git pull "$remote" "$target_branch" --rebase --autostash --verbose &&
  git merge "$source_branch" --no-ff --verbose
}

function mrinup() {
  local source_branch="$(git_current_branch)"
  local target_branch="${1:-develop}"
  local remote="${2:-origin}"

  git checkout "$target_branch" &&
  git pull "$remote" "$target_branch" --rebase --autostash --verbose &&
  git merge "$source_branch" --no-ff --verbose
  pushup "$remote"
}

# Need to be logged in to Azure CLI with permissions to access the Key Vault
# Activate venv and execute the script
# pull the values from the Key Vault and export them to an env file while switching - to _
# Deactivate venv

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

# Create a new virtual environment in ~/PythonVenvs
# Usage: mkv <name> [python_version]
# Defaults: python_version=3.12

function mkv() {
  local name="$1"
  local py_version="${2:-3.12}"

  if [[ -z "$name" ]]; then
    echo "Usage: mkv <name> [python_version]" >&2
    return 1
  fi

  local venvpath="$HOME/PythonVenvs/${name}"

  if [[ -d "$venvpath" ]]; then
    echo "Error: Virtual environment '$name' already exists at '$venvpath'" >&2
    return 1
  fi

  mkdir -p "$HOME/PythonVenvs"
  if ! "python$py_version" -m venv "$venvpath"; then
    echo "Error: Failed to create virtualenv using python$py_version" >&2
    return 1
  fi

  echo "Created venv at '$venvpath'"
  source "$venvpath/bin/activate"
}

# Create a new virtual environment in ~/PythonVenvs
# Usage: mkv <name> [python_version]
# Defaults: python_version=3.12

function mkuv() {
  local name="$1"
  local py_version="${2:-3.12}"

  if [[ -z "$name" ]]; then
    echo "Usage: mkuv <name> [python_version]" >&2
    return 1
  fi

  local venvpath="$HOME/PythonVenvs/${name}"

  if [[ -d "$venvpath" ]]; then
    echo "Error: Virtual environment '$name' already exists at '$venvpath'" >&2
    return 1
  fi

  mkdir -p "$HOME/PythonVenvs"
  if ! uv venv "$venvpath" --python "$py_version"; then
    echo "Error: Failed to create virtualenv using python$py_version" >&2
    return 1
  fi

  echo "Created venv at '$venvpath'"
  source "$venvpath/bin/activate"
}