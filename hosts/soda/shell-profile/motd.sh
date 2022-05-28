find -L /ascii -type f -print0 | shuf -zn1 | xargs -0 cat

bootup() {
    tbold="$(tput bold)"
    tpurple="$(tput setaf 5)"
    tred_bold="$(tput bold; tput setaf 1)"
    tblue="$(tput setaf 4)"
    treset="$(tput sgr0)"

    echo
    #neofetch -L

    source /etc/os-release
    os_name=${PRETTY_NAME:-$NAME}
    memory_usage=$(free -m | awk '/^Mem/ { printf "%sMB / %sMB\n", $3, $2}')
    online_now=$(w -sh | wc -l)
    server_time=$(date +'%A, %B %d, %T %z')

    if [[ $online_now -gt 1 ]]; then
        # Create a list of online users.
        online_users=$(w -sh | awk '{print $1}' | uniq | tr "\n" " " | sed "s| |, |g;s|, $||g")
    else
        online_users="just you"
    fi

    printf "${tpurple}${tbold}soda${treset} ${tpurple}is currently using${treset} ${tbold}$os_name${treset} ${tpurple}as our OS${treset}
${tpurple}we are running on${treset} ${tbold}$memory_usage${treset} ${tpurple}of RAM${treset}
${tpurple}and we have${treset} ${tbold}$online_now${treset} ${tpurple}online user(s)!${treset} ($online_users)\n"

    current_date=$(date +'%m-%d')
    current_year=$(date +'%Y')
    current_month="$(date +'%b')"
    current_day="$(date +'%e' | sed 's|^\s||')"
    soda_bday="04-10"

    if [[ $current_day -ne 10 ]] && [[ $current_day -lt 10 ]] && [[ $current_month == "Apr" ]]; then
        printf "\n${tred_bold}[!]${treset} btw it's ${tbold}$(( 10 - current_day ))${treset} day(s) (April 10th) till Soda's ${tbold}$(( current_year - 2019 ))${treset} year anniversary!\n"
    fi

    if [[ $current_date -eq $soda_bday ]]; then
        printf "\n${tred_bold}HEY YOU!${treset} ${tblue}Today is the${treset} ${tbold}$(( current_year - 2019 ))${treset} ${tblue}year anniversary of Soda's creation!${treset} ${tbold}Happy Birthday Soda!${treset}\n"
        sleep 3s
    fi

    printf "\n${tbold}Who's been around?${treset}\n"
    last | sed -r "/(^$|^wtmp|^reboot)/d" | head -n 5

    dickswing=$(last | sed -r "/^$/d;/^(wtmp|reboot)/d;/\(00:0[0-1]\)/d" | awk '{print $1}' | sort | uniq -c | sort -nr | sed -r "s/^\s+//")
    as_of=$(last | grep "wtmp" | awk '{print "from", $4, $5, $7}')
    echo -e "\n${tbold}Dickswing ($as_of to now):${treset}\n$dickswing"
    echo -e "\033[0;31mNOTE\033[0m: must be logged in for more than 1 minute to be counted."
}

bootup
