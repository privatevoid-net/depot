# allow using comments in interactive
setopt interactive_comments

# basic support for the omz theme format
setopt prompt_subst

# completions
autoload -U compinit
compinit
# allow fully dynamic alias completion - like it's supposed to be
unsetopt complete_aliases

setopt glob_complete
setopt glob_star_short
unsetopt bad_pattern
