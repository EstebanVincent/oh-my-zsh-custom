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

# Returns "--org https://dev.azure.com/ORG --project PROJECT --repository REPO" parsed from remote URL
# Supports SSH aliases: devops-alias:v3/ORG/PROJECT/REPO
# Usage: _az_pr_args [remote]
function _az_pr_args() {
  local remote="${1:-origin}"
  local url org project repo
  url=$(git remote get-url "$remote")
  org=$(echo "$url"     | sed 's|.*v3/\([^/]*\)/.*|\1|')
  project=$(echo "$url" | sed 's|.*v3/[^/]*/\([^/]*\)/.*|\1|')
  repo=$(echo "$url"    | sed 's|.*v3/[^/]*/[^/]*/\([^/]*\)|\1|')
  echo "--org https://dev.azure.com/$org --project $project --repository $repo"
}

# Gitflow functions
# feature start <name> [remote]  — branch off develop
# feature finish [name] [remote] — merge into develop, delete branch
function feature() {
  local cmd="$1"
  local name="$2"
  local remote="${3:-origin}"
  case "$cmd" in
    start)
      [[ -z "$name" ]] && echo "Usage: feature start <name> [remote]" && return 1
      git switch "$(git_develop_branch)" &&
      git pull "$remote" "$(git_develop_branch)" --rebase --autostash --verbose &&
      git switch --create "feature/$name"
      ;;
    finish)
      local branch="${name:+feature/$name}"
      local branch="${branch:-$(git_current_branch)}"
      git push "$remote" "$branch" --verbose &&
      az repos pr create $(_az_pr_args "$remote") \
        --source-branch "$branch" \
        --target-branch "$(git_develop_branch)" \
        --title "feat: $branch → $(git_develop_branch)" \
        --open
      ;;
    *)
      echo "Usage: feature <start|finish> [name] [remote]"
      ;;
  esac
}

# release start <version> [remote] — branch off develop
# release finish <version> [remote] — merge into main + develop, tag, delete
function release() {
  local cmd="$1"
  local version="$2"
  local remote="${3:-origin}"
  [[ -z "$version" ]] && echo "Usage: release <start|finish> <version> [remote]" && return 1
  local branch="release/$version"
  case "$cmd" in
    start)
      git switch "$(git_develop_branch)" &&
      git pull "$remote" "$(git_develop_branch)" --rebase --autostash --verbose &&
      git switch --create "$branch"
      ;;
    finish)
      git push "$remote" "$branch" --verbose &&
      az repos pr create $(_az_pr_args "$remote") \
        --source-branch "$branch" \
        --target-branch "$(git_main_branch)" \
        --title "release: $version → $(git_main_branch)" \
        --open &&
      az repos pr create $(_az_pr_args "$remote") \
        --source-branch "$branch" \
        --target-branch "$(git_develop_branch)" \
        --title "release: $version → $(git_develop_branch)" \
        --open
      ;;
    *)
      echo "Usage: release <start|finish> <version> [remote]"
      ;;
  esac
}

# hotfix start <name> [remote]  — branch off main
# hotfix finish <name> [remote] — merge into main + develop, tag, delete
function hotfix() {
  local cmd="$1"
  local name="$2"
  local remote="${3:-origin}"
  [[ -z "$name" ]] && echo "Usage: hotfix <start|finish> <name> [remote]" && return 1
  local branch="hotfix/$name"
  case "$cmd" in
    start)
      git switch "$(git_main_branch)" &&
      git pull "$remote" "$(git_main_branch)" --rebase --autostash --verbose &&
      git switch --create "$branch"
      ;;
    finish)
      git push "$remote" "$branch" --verbose &&
      az repos pr create $(_az_pr_args "$remote") \
        --source-branch "$branch" \
        --target-branch "$(git_main_branch)" \
        --title "hotfix: $name → $(git_main_branch)" \
        --open &&
      az repos pr create $(_az_pr_args "$remote") \
        --source-branch "$branch" \
        --target-branch "$(git_develop_branch)" \
        --title "hotfix: $name → $(git_develop_branch)" \
        --open
      ;;
    *)
      echo "Usage: hotfix <start|finish> <name> [remote]"
      ;;
  esac
}
