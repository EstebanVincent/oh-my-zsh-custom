#!/usr/bin/env zsh
# GitHub Copilot CLI ZSH plugin
# Sentinel prefix: `:` — same pattern as forgecode's zsh plugin
#
# Usage:
#   : <prompt>          Run copilot -p "<prompt>" (interactive, asks tool approval)
#   :yolo <prompt>      Run with --allow-all-tools (no approval prompts)
#   :resume [id]        Resume last session, or a specific session by ID prefix
#   :plan <prompt>      Run in plan mode (Shift+Tab equivalent)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
_COPILOT_BIN="${COPILOT_BIN:-copilot}"

# ---------------------------------------------------------------------------
# Syntax highlighting (requires zsh-syntax-highlighting)
# ---------------------------------------------------------------------------
ZSH_HIGHLIGHT_PATTERNS+=('(#s):[a-zA-Z0-9_-]#' 'fg=blue,bold')
ZSH_HIGHLIGHT_PATTERNS+=('(#s):[a-zA-Z0-9_-]# [[:graph:]]*' 'fg=white')
ZSH_HIGHLIGHT_PATTERNS+=('(#s): [[:graph:]]*' 'fg=white')
ZSH_HIGHLIGHT_HIGHLIGHTERS+=(pattern)

# ---------------------------------------------------------------------------
# Helper: run copilot interactively from within a ZLE widget
# ---------------------------------------------------------------------------
function _copilot_exec() {
    local _bin="${_COPILOT_BIN:-copilot}"  # double fallback if global is empty
    "$_bin" "$@"
}

# ---------------------------------------------------------------------------
# Main ZLE widget — intercepts Enter key
# ---------------------------------------------------------------------------
function copilot-accept-line() {
    local original_buffer="$BUFFER"

    # Only handle lines starting with ':'
    if [[ "$BUFFER" != :* ]]; then
        zle accept-line
        return
    fi

    local subcommand=""
    local prompt_text=""

    if [[ "$BUFFER" =~ "^:([a-zA-Z][a-zA-Z0-9_-]*)( (.*))?$" ]]; then
        # :subcommand [text]
        subcommand="${match[1]}"
        prompt_text="${match[3]}"
    elif [[ "$BUFFER" =~ "^: (.+)$" ]]; then
        # : prompt text (default send)
        prompt_text="${match[1]}"
    else
        # bare ':' with nothing after it — open interactive session
        print -s -- "$original_buffer"
        BUFFER=""
        zle redisplay
        _copilot_exec
        zle reset-prompt
        return 0
    fi

    # Add to shell history before executing
    print -s -- "$original_buffer"
    BUFFER=""
    zle redisplay

    case "$subcommand" in
        commit|c)
            local _bin="${_COPILOT_BIN:-copilot}"
            local _out=$(mktemp)
            local _spin='⣾⣽⣻⢿⡿⣟⣯⣷'
            # Marker triggers the sessionStart hook which injects git diff/status as context
            local _prompt='__CAVEMAN_COMMIT__ The staged diff and git status are in your context. Write a commit message: Conventional Commits `<type>(<scope>): <summary>` (≤50 chars, imperative, no period). Body only if why is non-obvious. Then run git commit. Never push.'

            "$_bin" \
                --disable-builtin-mcps \
                --no-ask-user \
                --no-custom-instructions \
                --silent \
                --allow-tool='shell(git)' \
                --deny-tool='shell(git push)' \
                --deny-tool='shell(git fetch)' \
                --deny-tool='shell(git pull)' \

                -p "$_prompt" \
                >|"$_out" 2>&1 &
            local _pid=$!

            # spinner
            local i=0
            tput civis 2>/dev/null
            while kill -0 "$_pid" 2>/dev/null; do
                i=$(( (i+1) % ${#_spin} ))
                printf "  \e[33m%s\e[0m committing..." "${_spin:$i:1}"
                sleep 0.1
                printf "\r\033[K"
            done
            tput cnorm 2>/dev/null

            cat "$_out"
            rm -f "$_out"
            ;;
        resume|r)
            if [[ -n "$prompt_text" ]]; then
                _copilot_exec --resume="$prompt_text"
            else
                _copilot_exec --resume
            fi
            ;;
        yolo)
            if [[ -z "$prompt_text" ]]; then
                echo "\n[copilot] :yolo requires a prompt" >/dev/tty
            else
                _copilot_exec --allow-all-tools -p "$prompt_text"
            fi
            ;;
        plan)
            # Plan mode: prompt copilot with the plan mode flag
            # Copilot doesn't expose a direct --plan flag yet, but we can note it in the prompt
            if [[ -z "$prompt_text" ]]; then
                echo "\n[copilot] :plan requires a prompt" >/dev/tty
            else
                _copilot_exec -p "Use plan mode to: $prompt_text"
            fi
            ;;
        help|h)
            echo
            echo "GitHub Copilot CLI ZSH Plugin"
            echo
            echo "  : <prompt>          Send prompt to copilot (interactive approval)"
            echo "  :commit             Generate a caveman-style commit and commit"
            echo "  :yolo <prompt>      Send prompt with --allow-all-tools"
            echo "  :resume [id]        Resume last or specific session by ID prefix"
            echo "  :plan <prompt>      Send prompt prefixed with 'Use plan mode to:'"
            echo "  :help               Show this help"
            echo
            ;;
        "")
            # `: prompt` — default send
            if [[ -n "$prompt_text" ]]; then
                _copilot_exec -p "$prompt_text"
            else
                _copilot_exec
            fi
            ;;
        *)
            # Unknown subcommand — treat everything as a prompt
            local full_prompt="$subcommand"
            [[ -n "$prompt_text" ]] && full_prompt="$subcommand $prompt_text"
            _copilot_exec -p "$full_prompt"
            ;;
    esac

    zle reset-prompt
    return 0
}

# ---------------------------------------------------------------------------
# Widget registration and key bindings
# ---------------------------------------------------------------------------
zle -N copilot-accept-line

function _copilot_apply_keybindings() {
    bindkey '^M' copilot-accept-line   # Enter
    bindkey '^J' copilot-accept-line   # Ctrl+J (also Enter in many terminals)
}

_copilot_apply_keybindings

# Re-apply after zsh-vi-mode reinitializes keymaps (no-op if not installed)
typeset -ga zvm_after_init_commands
zvm_after_init_commands+=('_copilot_apply_keybindings')
