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

delta_prompt_symbol() {
	if [[ "$1" -eq 0 ]]; then
		print -n '%F{red}'
	else
		print -n '%F{8}'
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
		PROMPT=" \$(delta_prompt_symbol \$?)Δ%f %F{8}$hostnamevar %c >%f "
	else
		PROMPT=" \$(delta_prompt_symbol \$?)Δ%f %F{8}%c >%f "
	fi

	zstyle ':vcs_info:*' enable git
	zstyle ':vcs_info:*' use-simple true
	zstyle ':vcs_info:git*' formats '%b'
	zstyle ':vcs_info:git*' actionformats '%b|%a'

	zstyle ':vcs_info:*' max-exports 2
}

delta_prompt_init "$@"

# xterm title
PROMPT_XTITLE=$'%{\033]0;%n@%M:%~\007%}'
PROMPT="${PROMPT_XTITLE}${PROMPT}"
