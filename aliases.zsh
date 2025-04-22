# git aliases
alias add='git add . && git status'
alias commit='git commit --verbose --message'
alias commitnv='git commit --verbose --no-verify --message'
alias pull='git pull --rebase --autostash --verbose'
alias push='git push --verbose'
alias undo='git reset --soft HEAD~1'
alias del='git branch -D'

# Docker aliases
alias up='docker compose up'
alias upb='docker compose up --build'

# Azure aliases
alias azl='az login'

# Python aliases

alias pi= 'pip install'
alias pir='pip install --upgrade pip && pip install -r requirements.txt'

# Other
alias c='clear'