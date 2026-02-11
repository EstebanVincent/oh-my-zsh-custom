# Pip aliases
alias pi='pip install --upgrade pip && pip install "$@"'
alias pir='pip install --upgrade pip && pip install --upgrade -r requirements.txt'
alias pire='pip install --upgrade pip && pip install --upgrade -r requirements.txt --extra-index-url https://${ACCESS_TOKEN_NAME}:${ACCESS_TOKEN_SECRET}@pkgs.dev.azure.com/LabCh/_packaging/innovation/pypi/simple/'

# UV aliases
alias uvs='uv sync --active --extra dev'
alias uvr='uv run --active'

# Python functions

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

# Create a new virtual environment in ~/PythonVenvs using uv
# Usage: mkuv <name> [python_version]
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
