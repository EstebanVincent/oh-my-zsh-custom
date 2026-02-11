# General aliases
alias c='clear'
alias ssha='ssh-add ~/.ssh/id_rsa'

# Fuzzy search with zle
# This setup enhances command history search by:
# 1. Using fzf to provide interactive fuzzy searching through command history
# 2. Binding Ctrl+R to trigger the fuzzy search
# 3. Configuring zle (Zsh Line Editor) to integrate the search results with the current command line
# 4. Setting options to display search results with syntax highlighting

function fuzzysearch() {
  BUFFER=$(history | fzf --tac --reverse | sed -E 's/^ *[0-9]+ +[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} +//')
  CURSOR=$#BUFFER
  zle redisplay
}
zle -N fuzzysearch
bindkey '^R' fuzzysearch
