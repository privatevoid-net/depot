find -L /ascii -type f -print0 | shuf -zn1 | xargs -0 cat

bootup() {
    esc_bold="\x1b[1m"
    esc_reset="\x1b[0m"
    esc_magenta="\x1b[35m"
    esc_red_bold="\x1b[1;31m"
    tblue="\x1b[34m"

    echo

    source /etc/os-release
    os_name=${PRETTY_NAME:-$NAME}
    memory_usage=$(free -m | awk '/^Mem/ { printf "%sMB / %sMB\n", $3, $2}')
    online_now=$(w -sh | wc -l)

    online_users="just you"

    if [[ $online_now -gt 1 ]]; then
        # Create a list of online users.
        online_users=$(w -sh | awk '{print $1}' | uniq | tr "\n" " " | sed "s| |, |g;s|, $||g")
    fi

    printf "${esc_magenta}${esc_bold}soda${esc_reset} ${esc_magenta}is currently using${esc_reset} ${esc_bold}$os_name${esc_reset} ${esc_magenta}as our OS${esc_reset}
${esc_magenta}we are running on${esc_reset} ${esc_bold}$memory_usage${esc_reset} ${esc_magenta}of RAM${esc_reset}
${esc_magenta}and we have${esc_reset} ${esc_bold}$online_now${esc_reset} ${esc_magenta}online user(s)!${esc_reset} ($online_users)\n"

    logins_this_month="$(last --time-format iso | sed "/reboot/d" | grep "$(date +'%Y-%m')" | wc -l)"
    printf "\n${esc_bold}Who's been around?${esc_reset} (${logins_this_month} logins this month)\n"
    last -R | sed -r "/(^$|^wtmp|^reboot)/d" | head -n 5

    dickswing=$(last | sed -r "/^$/d;/^(wtmp|reboot)/d;/\(00:0[0-1]\)/d" | awk '{print $1}' | sort | uniq -c | sort -nr | sed -r "s/^\s+//")
    as_of=$(last | grep "wtmp" | awk '{print "from", $4, $5, $7}')
    echo -e "\n${esc_bold}Dickswing ($as_of to now):${esc_reset}\n$dickswing"
    echo -e "${esc_red_bold}NOTE${esc_reset}: must be logged in for more than 1 minute to be counted."
}

bootup

test -e /motd.txt && cat /motd.txt
