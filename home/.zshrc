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
ZSH_HIGHLIGHT_STYLES[command]='fg=#4be3a0,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#4fd6e0,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#4fd6e0,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#4fd6e0'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#c792ea,underline'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#c792ea,bold'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#c792ea'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#c792ea'
ZSH_HIGHLIGHT_STYLES[path]='fg=#ffffff,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#ffcb6b'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#7aa2ff'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#7aa2ff'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#ffcb6b'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#ffcb6b'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#ffcb6b'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ff5370,bold'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#666666'

# fzf: Ctrl+R historial, Ctrl+T archivos
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
export FZF_DEFAULT_OPTS='--color=fg:#d9d9d9,bg:-1,hl:#fafafa,fg+:#ffffff,bg+:#1a1a1a,hl+:#fafafa,pointer:#fafafa,prompt:#fafafa,info:#8c8c8c,border:#2a2a2a --border=rounded --height=40%'

# alias
if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --group-directories-first --git'
  alias la='eza -la --icons --group-directories-first --git'
  alias tree='eza --tree --icons'
fi
command -v batcat >/dev/null && alias cat='batcat --paging=never --theme=ansi'
command -v dircolors >/dev/null && eval "$(dircolors -b)"
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias wall='mono-wall'
alias update='sudo apt update && sudo apt full-upgrade'

# prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# saludo al abrir kitty
if [[ -o interactive && "$TERM" == xterm-kitty ]] && command -v fastfetch >/dev/null; then
  fastfetch --logo-type small 2>/dev/null
fi
