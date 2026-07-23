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

# gff start <name> [remote]  — branch off develop
# gff end [name] [remote] — merge into develop, delete branch
function gff() {
  local cmd="$1"
  local name="$2"
  local remote="${3:-origin}"
  case "$cmd" in
    start)
      [[ -z "$name" ]] && echo "Usage: gff start <name> [remote]" && return 1
      git switch "$(git_develop_branch)" &&
      git pull "$remote" "$(git_develop_branch)" --rebase --autostash --verbose &&
      git switch --create "feature/$name"
      ;;
    end)
      local branch="${name:+feature/$name}"
      local branch="${branch:-$(git_current_branch)}"
      git push "$remote" "$branch" --verbose &&
      az repos pr create $(_az_pr_args "$remote") \
        --source-branch "$branch" \
        --target-branch "$(git_develop_branch)" \
        --title "feature: $name → $(git_develop_branch)" \
        --open
      ;;
    *)
      echo "Usage: gff <start|end> [name] [remote]"
      ;;
  esac
}

# gfr start <version> [remote] — branch off develop
# gfr end <version> [remote] — merge into main + develop, tag, delete
function gfr() {
  local cmd="$1"
  local version="$2"
  local remote="${3:-origin}"
  [[ -z "$version" ]] && echo "Usage: gfr <start|end> <version> [remote]" && return 1
  local branch="release/$version"
  case "$cmd" in
    start)
      git switch "$(git_develop_branch)" &&
      git pull "$remote" "$(git_develop_branch)" --rebase --autostash --verbose &&
      git switch --create "$branch"
      ;;
    end)
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
      echo "Usage: release <start|end> <version> [remote]"
      ;;
  esac
}

# gfh start <name> [remote]  — branch off main
# gfh end <name> [remote] — merge into main + develop, tag, delete
function gfh() {
  local cmd="$1"
  local name="$2"
  local remote="${3:-origin}"
  [[ -z "$name" ]] && echo "Usage: gfh <start|end> <name> [remote]" && return 1
  local branch="hotfix/$name"
  case "$cmd" in
    start)
      git switch "$(git_main_branch)" &&
      git pull "$remote" "$(git_main_branch)" --rebase --autostash --verbose &&
      git switch --create "$branch"
      ;;
    end)
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
      echo "Usage: gfh <start|end> <name> [remote]"
      ;;
  esac
}
