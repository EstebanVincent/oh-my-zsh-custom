# Fuzzy search with zle
# This setup enhances command history search by:
# 1. Using fzf to provide interactive fuzzy searching through command history
# 2. Binding Ctrl+R to trigger the fuzzy search
# 3. Configuring zle (Zsh Line Editor) to integrate the search results with the current command line
# 4. Setting options to display search results with syntax highlighting
function fuzzysearch() {
  BUFFER=$(history | fzf --tac --reverse | sed 's/ *[0-9]* *//')
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
  pull "$remote" "$target_branch" &&
  git rebase "$source_branch" --verbose
}

function mrin() {
  local source_branch="$(git_current_branch)"
  local target_branch="${1:-develop}"
  local remote="${2:-origin}"

  git checkout "$target_branch" &&
  pull "$remote" "$target_branch" &&
  git merge "$source_branch" --no-ff --verbose
}

function gcnv() {
  git commit --verbose --message "$1" --no-verify
}

function kv2env() {
  local kv_name="$1"
  local env_file="${2:-$kv_name.env}"
  local script_path="/Users/esvi/Library/CloudStorage/OneDrive-Professional/Chanel/DevOps/LabCh/Common/scripts/azure/kv_secrets_to_env.py"
  local venv_path="$HOME/Documents/MyEnvs/scripts-env"

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

# Create a new virtual environment in ~/Documents/MyEnvs
# Usage: mkv <name> [python_version]
# Defaults: python_version=3.12

function mkv() {
  local name="$1"
  local py_version="${2:-3.12}"

  if [[ -z "$name" ]]; then
    echo "Usage: mkv <name> [python_version]" >&2
    return 1
  fi

  local version_prefix="${py_version//./}"  # 3.12 → 312
  local final_name="${version_prefix}-${name}-venv"
  local venvpath="$HOME/Documents/MyEnvs/$final_name"

  if [[ -d "$venvpath" ]]; then
    echo "Error: Virtual environment '$final_name' already exists at '$venvpath'" >&2
    return 1
  fi

  mkdir -p "$HOME/Documents/MyEnvs"
  if ! "python$py_version" -m venv "$venvpath"; then
    echo "Error: Failed to create virtualenv using python$py_version" >&2
    return 1
  fi

  echo "Created venv at '$venvpath'"
  source "$venvpath/bin/activate"
}