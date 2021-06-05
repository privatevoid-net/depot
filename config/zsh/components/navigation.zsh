alias d="dirs -v | head -n10"

# backdir auto expansion: ... -> ../..
function rationalise-dot() {
	local MATCH # keep the regex match from leaking to the environment
	if [[ $LBUFFER =~ '(^|/| |      |'$'\n''|\||;|&)\.\.$' && ! $LBUFFER = p4* ]]; then
			#if [[ ! $LBUFFER = p4* && $LBUFFER = *.. ]]; then
			LBUFFER+=/..
	else
			zle self-insert
	fi
}
zle -N rationalise-dot
bindkey . rationalise-dot
bindkey -M isearch . self-insert

# absolutize a relative path, or vice versa, or alternatively insert the cwd
function insert-cwd-or-absolute() {
	local MATCH # keep the regex match from leaking to the environment
	# match anything that could be a path
	if [[ $LBUFFER =~ '(|'$'\n''|\||;|&)[^= ]+$' && ! $LBUFFER = p4* ]]; then
		# make sure it exists
		if [[ -e $MATCH ]]; then
			local XMATCH="$MATCH"
			# absolute - make relative
			if [[ $XMATCH =~ '^/' ]]; then
				# cut away the last piece of the buffer
				local LENGTH=$(( $#LBUFFER - $#XMATCH ))
				LBUFFER="${LBUFFER:0:${LENGTH}}"
				# and replace it with a relative realpath
				LBUFFER+="$(realpath --relative-to=. $XMATCH)"
			else # relative - make absolute
				local LENGTH=$(( $#LBUFFER - $#XMATCH ))
				LBUFFER="${LBUFFER:0:${LENGTH}}"
				LBUFFER+="$(realpath $XMATCH)"
			fi
		fi
	else
		LBUFFER+=$(pwd)
	fi
}
zle -N insert-cwd-or-absolute
bindkey '\ed' insert-cwd-or-absolute
