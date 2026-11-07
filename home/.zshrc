# mono-rice · zsh
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS AUTO_CD INTERACTIVE_COMMENTS

autoload -Uz compinit && compinit -q
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# plugins (paquetes de Debian)
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#666666'
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#ffffff,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#ffffff,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#ffffff,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=#cccccc,underline'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#999999'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#666666'

# fzf: Ctrl+R historial, Ctrl+T archivos
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
export FZF_DEFAULT_OPTS='--color=bw --border=rounded --height=40%'

# alias
if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --group-directories-first --git'
  alias la='eza -la --icons --group-directories-first --git'
  alias tree='eza --tree --icons'
fi
command -v batcat >/dev/null && alias cat='batcat --paging=never --theme=ansi'
alias ..='cd ..'
alias ...='cd ../..'
alias wall='~/mono-rice/scripts/setwall.sh'
alias update='sudo apt update && sudo apt full-upgrade'

# prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# saludo al abrir kitty
if [[ -o interactive && "$TERM" == xterm-kitty ]] && command -v fastfetch >/dev/null; then
  fastfetch --logo-type small 2>/dev/null
fi
