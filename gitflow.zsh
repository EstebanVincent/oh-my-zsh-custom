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

# Returns "OWNER/REPO" parsed from a GitHub remote URL (https, ssh, or ssh alias)
# Usage: _gh_repo [remote]
function _gh_repo() {
  local remote="${1:-origin}"
  git remote get-url "$remote" | sed -e 's|\.git$||' -e 's|.*[:/]\([^/:]*/[^/:]*\)$|\1|'
}

# Use copilot CLI (--output-format json) to generate PR title+description,
# then create PR(s) via gh (GitHub remotes) or az (Azure DevOps remotes).
# Usage: _gf_copilot_pr <source-branch> <remote> <target-branch> [extra-target...]
function _gf_copilot_pr() {
  local source_branch="$1" remote="$2"
  shift 2
  local targets=("$@")
  local first_target raw json title description is_github

  first_target="${targets[1]}"
  [[ "$(git remote get-url "$remote")" == *github* ]] && is_github=1

  if [[ -n "$is_github" ]] && ! gh auth status --hostname github.com >/dev/null 2>&1; then
    local answer
    echo -n "[gf] Not logged in to GitHub CLI. Run 'gh auth login' now? (y/n) "
    read answer
    [[ "$answer" == 'y' ]] && gh auth login --hostname github.com || return 1
  fi

  raw=$("${_COPILOT_BIN:-copilot}" \
    --disable-builtin-mcps \
    --no-ask-user \
    --no-custom-instructions \
    --output-format json \
    --model 'claude-sonnet-5.5' \
    -p "Generate a PR title (conventional commits, ≤72 chars) and short markdown description for branch: $source_branch → $first_target. Output ONLY a JSON object: {\"title\": \"...\", \"description\": \"...\"}" 2>/dev/null)

  # JSONL: final response lives in .data.content of "assistant.message" events
  json=$(printf '%s' "$raw" | \
    jq -r 'select(.type == "assistant.message") | .data.content' 2>/dev/null | \
    grep '"title"' | tail -1)

  title=$(printf '%s' "$json" | jq -r '.title' 2>/dev/null)
  description=$(printf '%s' "$json" | jq -r '.description' 2>/dev/null)

  if [[ -z "$title" || "$title" == "null" ]]; then
    echo "[gf] copilot: failed to parse PR title — raw output:" >&2
    printf '%s\n' "$raw" >&2
    return 1
  fi

  if [[ -n "$is_github" ]]; then
    local gh_repo=$(_gh_repo "$remote") pr_url
    for target in "${targets[@]}"; do
      pr_url=$(gh pr create --repo "$gh_repo" \
        --head "$source_branch" \
        --base "$target" \
        --title "$title" \
        --body "$description") || continue
      echo "$pr_url"
      gh pr view "$pr_url" --web
    done
    return
  fi

  local az_args=$(_az_pr_args "$remote")
  for target in "${targets[@]}"; do
    az repos pr create ${=az_args} \
      --source-branch "$source_branch" \
      --target-branch "$target" \
      --title "$title" \
      --description "$description" \
      --open | jq -r '"PR #\(.pullRequestId): \(.title)\n\(.webUrl // .url)"'
  done
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
      _gf_copilot_pr "$branch" "$remote" "$(git_develop_branch)"
      ;;
    *)
      echo "Usage: gff <start|end> [name] [remote]"
      ;;
  esac
}

# gtf start <name> [remote]  — branch off main (trunk-based)
# gtf end [name] [remote] — PR into main
function gtf() {
  local cmd="$1"
  local name="$2"
  local remote="${3:-origin}"
  case "$cmd" in
    start)
      [[ -z "$name" ]] && echo "Usage: gtf start <name> [remote]" && return 1
      git switch "$(git_main_branch)" &&
      git pull "$remote" "$(git_main_branch)" --rebase --autostash --verbose &&
      git switch --create "feature/$name"
      ;;
    end)
      local branch="${name:+feature/$name}"
      local branch="${branch:-$(git_current_branch)}"
      git push "$remote" "$branch" --verbose &&
      _gf_copilot_pr "$branch" "$remote" "$(git_main_branch)"
      ;;
    *)
      echo "Usage: gtf <start|end> [name] [remote]"
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
      _gf_copilot_pr "$branch" "$remote" "$(git_main_branch)" "$(git_develop_branch)"
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
      _gf_copilot_pr "$branch" "$remote" "$(git_main_branch)" "$(git_develop_branch)"
      ;;
    *)
      echo "Usage: gfh <start|end> <name> [remote]"
      ;;
  esac
}
