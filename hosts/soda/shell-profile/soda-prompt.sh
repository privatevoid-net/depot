if [ -n "${BASH_VERSION-}" ]; then
	if test $(id -u) -eq 0; then
		PS1='\h # '
	else
		PS1='\h % '
	fi
fi
