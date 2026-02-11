# Git aliases
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

# Git functions

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
