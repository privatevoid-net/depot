# zsh-syntax-highlighting
typeset -A ZSH_HIGHLIGHT_STYLES

ZSH_HIGHLIGHT_STYLES[precommand]='fg=33'

ZSH_HIGHLIGHT_STYLES[arg0]='fg=39'

ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=229'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=228'

ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=blue'

ZSH_HIGHLIGHT_STYLES[path]='none'
# HACK: performance fix assuming "none" isn't truly none
ZSH_HIGHLIGHT_DIRS_BLACKLIST+=(/*)

# fix aliased highlighting of suid precmds
typeset -A ZSH_HIGHLIGHT_PATTERNS

ZSH_HIGHLIGHT_PATTERNS+=('doas' 'fg=33')
ZSH_HIGHLIGHT_PATTERNS+=('sudo' 'fg=33')

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main pattern)

# set up LS_COLORS
if which dircolors >/dev/null 2>&1; then
	export $(dircolors)
fi

# colorful tab completion listings
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
