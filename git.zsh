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

# Prune local branches with gone or missing upstream
# Lists branches whose upstream was deleted ([gone]) and branches with no tracking at all
# Prompts separately for each group before deleting
# Usage: prunelocal

function prunelocal() {
  echo "Fetching and pruning..."
  git fetch --prune -q

  echo ""
  echo "Branches with a \"[gone]\" upstream branch:"
  echo "-----"
  git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads/ | awk '$2 == "[gone]" {print $1}'
  local gone=$(git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads/ | awk '$2 == "[gone]"' | wc -l)

  echo ""
  echo "Branches not tracking an upstream branch:"
  echo "-----"
  git for-each-ref --format '%(refname:short) %(upstream)' refs/heads/ | awk '$2 == "" {print $1}'
  local nontracking=$(git for-each-ref --format '%(refname:short) %(upstream)' refs/heads/ | awk '$2 == ""' | wc -l)

  echo ""

  local remove_gone remove_local

  if (( gone )); then
    echo -n "Delete [gone] branches? (y/n) "
    read remove_gone
  fi

  if (( nontracking )); then
    echo -n "Delete branches w/out tracking? (y/n) "
    read remove_local
  fi

  echo ""

  if [[ "$remove_gone" == 'y' ]]; then
    git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads/ | awk '$2 == "[gone]" {print $1}' | xargs git branch -D
  elif (( gone )); then
    echo "Skipping \"[gone]\" branches"
    echo ""
  fi

  if [[ "$remove_local" == 'y' ]]; then
    git for-each-ref --format '%(refname:short) %(upstream)' refs/heads/ | awk '$2 == "" {print $1}' | xargs git branch -D
  elif (( nontracking )); then
    echo "Skipping branches w/out tracking"
  fi

  echo "Done."
}
