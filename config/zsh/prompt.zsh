# Delta
# Reference/Resources:
#
# Prompt Expansion:
# http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
# http://unix.stackexchange.com/questions/157693/howto-include-output-of-a-script-into-the-zsh-prompt
#
# vcs_info
# https://github.com/zsh-users/zsh/blob/master/Misc/vcs_info-examples
# http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#Version-Control-Information
#
__shlvl_deep() {
	[[ $SHLVL -gt 1 ]]
}

delta_prompt_symbol() {
	if [[ "$1" -eq 0 ]]; then
		local color
		if __shlvl_deep; then
			color=blue
		else
			color=red
		fi
		print -n "%F{$color}"
	else
		print -n '%F{8}'
	fi	
}

delta_prompt_nix_shell() {
	if __shlvl_deep; then
		print -n " %F{cyan}>%F{blue}>%F{8}"
		tr : '\n' <<<$PATH | grep '^/nix/store' | while read storepath; do
			print -n " ${${storepath#*-}%/*}"
		done
		print -n '%f\n '
	else
		print -n ' '
	fi
}

delta_prompt_init() {

	local hostnamevar PRETTY_HOSTNAME CHASSIS LOCATION
	if [[ -f /etc/machine-info ]]; then
		. /etc/machine-info
		if [[ -n $PRETTY_HOSTNAME ]]; then
			hostnamevar=$PRETTY_HOSTNAME
		fi
	fi
	if [[ -z $hostnamevar ]]; then
		hostnamevar='%m'
	fi


	if [[ -n $SSH_CONNECTION ]]; then
		PROMPT="$(delta_prompt_nix_shell)\$(delta_prompt_symbol \$? red)Δ%f %F{8}$hostnamevar %c >%f "
	else
		PROMPT="$(delta_prompt_nix_shell)\$(delta_prompt_symbol \$? red)Δ%f %F{8}%c >%f "
	fi
	unfunction delta_prompt_nix_shell

	zstyle ':vcs_info:*' enable git
	zstyle ':vcs_info:*' use-simple true
	zstyle ':vcs_info:git*' formats '%b'
	zstyle ':vcs_info:git*' actionformats '%b|%a'

	zstyle ':vcs_info:*' max-exports 2
}

delta_prompt_git_status() {
    local message=""
    local message_color="%F{green}"

    # https://git-scm.com/docs/git-status#_short_format
    local staged=$(git status --porcelain 2>/dev/null | grep -e "^[MADRCU]")
    local unstaged=$(git status --porcelain 2>/dev/null | grep -e "^[MADRCU? ][MADRCU?]")

    if [[ -n ${staged} ]]; then
        message_color="%F{red}"
    elif [[ -n ${unstaged} ]]; then
        message_color="%F{yellow}"
    fi

    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -n ${branch} ]]; then
        message+="${message_color}${branch}%f"
    fi

    echo -n "${message}"
}


delta_prompt_init "$@"

# xterm title
PROMPT_XTITLE=$'%{\033]0;%n@%M:%~\007%}'
PROMPT="${PROMPT_XTITLE}${PROMPT}"
RPROMPT='$(delta_prompt_git_status)'
