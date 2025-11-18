# git aliases
alias add='git add . && git status'
alias commit='git commit --verbose --message'
alias commitnv='git commit --verbose --no-verify --message'
alias fetch='git fetch --verbose'
alias fetchp='git fetch --prune --verbose'
alias pull='git pull --rebase --autostash --verbose'
alias push='git push --verbose'
alias undo='git reset --soft HEAD~1'
alias del='git branch -D'
alias diff='git diff --stat'
alias log='git log --stat'

alias sw='git switch'
alias swd='git switch $(git_develop_branch)'
alias swm='git switch $(git_main_branch)'
alias swc='git switch --create'

alias stash='git stash push --include-untracked --message'
alias stashl='git stash list'
alias stashp='git stash pop'
alias stashs='git stash show -p'

# Docker aliases
alias up='docker compose up'
alias upb='docker compose up --build'
alias dbp='docker builder prune -f'
alias dip='docker image prune -f'

# Azure aliases
alias azl='az login'

# kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kex='kubectl exec -it'

# Terraform aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'

# Pip aliases
alias pi='pip install --upgrade pip && pip install "$@"'
alias pir='pip install --upgrade pip && pip install --upgrade -r requirements.txt'
alias pire='pip install --upgrade pip && pip install --upgrade -r requirements.txt --extra-index-url https://${ACCESS_TOKEN_NAME}:${ACCESS_TOKEN_SECRET}@pkgs.dev.azure.com/LabCh/_packaging/innovation/pypi/simple/'

# UV aliases
alias uvs='uv sync --active --extra dev'
alias uvr='uv run --active'

# Other
alias c='clear'
alias ssha='ssh-add ~/.ssh/id_rsa'