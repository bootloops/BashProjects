#!/bin/bash

## SUPPORT COLORS CHECK ##
clear # to start

######

## COLORS ##


RESET="\033[0m"

supports_256_colors() {
  [[ "$TERM" =~ 256color ]] && return 0 || return 1
}

color() {
  local fg=$1
  local bg=$2
  local text=$3

  if supports_256_colors; then
    # 256-color mode
    [[ -n $fg ]] && printf "\033[38;5;${fg}m"
    [[ -n $bg ]] && printf "\033[48;5;${bg}m"
  else
    # 16-color fallback
    case $fg in
      black) printf "\033[30m" ;;
      red) printf "\033[31m" ;;
      green) printf "\033[32m" ;;
      yellow) printf "\033[33m" ;;
      blue) printf "\033[34m" ;;
      magenta) printf "\033[35m" ;;
      cyan) printf "\033[36m" ;;
      white) printf "\033[37m" ;;
    esac
    case $bg in
      black) printf "\033[40m" ;;
      red) printf "\033[41m" ;;
      green) printf "\033[42m" ;;
      yellow) printf "\033[43m" ;;
      blue) printf "\033[44m" ;;
      magenta) printf "\033[45m" ;;
      cyan) printf "\033[46m" ;;
      white) printf "\033[47m" ;;
    esac
  fi

  printf "%s${RESET}" "$text"
}

##### ####### #### ####### ####### #####
#!/bin/bash
# DodgeBash v0.2 — Bash terminal mini-game

###################################
##   COLOR / EMOJI CAPABILITY    ##
###################################

RESET="\033[0m"
supports_256_colors() { [[ "$TERM" =~ 256color ]]; }
supports_emoji() { printf "✅" | grep -q "✅"; }

if supports_256_colors; then
  RED="\033[38;5;196m"
  GREEN="\033[38;5;46m"
  YELLOW="\033[38;5;226m"
  BLUE="\033[38;5;33m"
else
  RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; BLUE="\033[34m"
fi

if supports_emoji; then
  ERR_ICON="❌"
  FIX_ICON="🛠️"
  SYS_ICON="💻"
  INTRUDER_ICON="💀"
  VIRUS_ICON="🦠"
else
  ERR_ICON="X"
  FIX_ICON="*"
  SYS_ICON="@"
  INTRUDER_ICON="0xFH"
  VIRUS_ICON="xVx"
fi

###################################
##          GAME STATE           ##
###################################

lives=3
score=101
character="$SYS_ICON"
x_pos=5
y_pos=3

map=(
  "###################################### TRAINER SIM #######################################"
  "#........................................................................................."
  "#........................................................................................."
  "#........................................................................................."
  "#........................................................................................."
  "#........................................................................................."
  "#........................................................................................."
  "#........................................................................................."
  "#........................................................................................."
  "#........................................................................................."
  "#........................................................................................."
  "#........................................................................................."
  "#........................................................................................."
  "#........................................................................................."
  "##########################################################################################"
)

errors=()   # active error positions
fixes=() # active fix positions
intruders=()  # active intruder positions
viruses=()  # active virus positions


# tuning params
ERROR_BASE=18
FIX_BASE=36
ERROR_SCORE_SCALE=120
FIX_SCORE_SCALE=200
ERROR_TIME_SCALE=30
FIX_TIME_SCALE=60
ERROR_MIN=3
FIX_MIN=6

# mark start time
START_TIME=$(date +%s)

# CHANGE DIFFICULTY BASE ON TIME/SCORE
compute_divisors() {
  elapsed=$(( $(date +%s) - START_TIME ))
  error_divisor=$(( ERROR_BASE - score / ERROR_SCORE_SCALE - elapsed / ERROR_TIME_SCALE ))
  fix_divisor=$(( FIX_BASE - score / FIX_SCORE_SCALE - elapsed / FIX_TIME_SCALE ))
  (( error_divisor < ERROR_MIN )) && error_divisor=$ERROR_MIN
  (( fix_divisor  < FIX_MIN  )) && fix_divisor=$FIX_MIN
}

tick=0


#############################################################
##           FUNCTIONS           #########################################
############################################################

###################################
##         OPTIMIZED RENDER       ##
###################################

render_map() {
  # Move cursor to top-left instead of clearing
  printf "\033[H"

  # Header
  echo -e "${YELLOW}=== DodgeBash ===${RESET}"
  echo -e "Lives: ${GREEN}${lives}${RESET}  Score: ${BLUE}${score}${RESET}"
  echo

  # Precompute errors and fixes in associative arrays for fast lookup
  declare -A error_map fix_map
  for e in "${errors[@]}"; do
    IFS=, read -r ex ey <<< "$e"
    error_map["$ey,$ex"]=1
  done
  for f in "${fixes[@]}"; do
    IFS=, read -r fx fy <<< "$f"
    fix_map["$fy,$fx"]=1
  done

  # Render each row
  for i in "${!map[@]}"; do
    row_str=""
    row="${map[$i]}"
    for ((j=0; j<${#row}; j++)); do
      symbol="${row:$j:1}"

      # Check errors first
      if [[ -n "${error_map[$i,$j]}" ]]; then
        symbol="${RED}${ERR_ICON}${RESET}"
      # Then check fixes
      elif [[ -n "${fix_map[$i,$j]}" ]]; then
        symbol="${YELLOW}${FIX_ICON}${RESET}"
      # Then intruders
      elif [[ " ${intruders[@]} " =~ " $j,$i " ]]; then
        symbol="${RED}${INTRUDER_ICON}${RESET}"
      # Then virus
      elif [[ " ${viruses[@]} " =~ " $j,$i " ]]; then
        symbol="${RED}${VIRUS_ICON}${RESET}"
      # Then player
      elif [[ $i -eq $y_pos && $j -eq $x_pos ]]; then
        symbol="$character"
      fi

      row_str+="$symbol"
    done
    echo -e "$row_str"
  done
  printf "\033[%s;1H" "$(( ${#map[@]} + 4 ))"  # move cursor to line after map
  printf "\033[2K\r"  # clear the line
  echo " "  # optional blank
  
}

spawn_virus() {
  local vx=$((RANDOM % (${#map[0]} - 4) + 1))
  local vy=$((RANDOM % (${#map[@]} - 3) + 1))
  viruses+=("$vx,$vy")
}
move_viruses() {
  new_viruses=()
  for v in "${viruses[@]}"; do
    IFS=, read -r vx vy <<< "$v"
    ((vx--))  # virus moves left
    if (( vx <= 0 )); then continue; fi
    if (( vx == x_pos && vy == y_pos )); then
      echo -e "${RED}🦠 Virus detected!${RESET}"
      virus_round
    else
      new_viruses+=("$vx,$vy")
    fi
  done
  viruses=("${new_viruses[@]}")
}

spawn_intruder() {
  local ix=$((RANDOM % (${#map[0]} - 4) + 1))
  local iy=$((RANDOM % (${#map[@]} - 3) + 1))
  intruders+=("$ix,$iy")
}

move_intruders() {
  new_intruders=()
  for intr in "${intruders[@]}"; do
    IFS=, read -r ix iy <<< "$intr"
    ((ix--))  # intruder moves left
    if (( ix <= 0 )); then continue; fi  # off-screen
    # check collision with player
    if (( ix == x_pos && iy == y_pos )); then
      echo -e "${RED}👾 Intruder detected!${RESET}"
      intruder_round
    else
      new_intruders+=("$ix,$iy")
    fi
  done
  intruders=("${new_intruders[@]}")
}


spawn_fixes() {
  local fx=$((RANDOM % (${#map[0]} - 4) + 1))
  local fy=$((RANDOM % (${#map[@]} - 3) + 1))
  fixes+=("$fx,$fy")
}

move_fixes() {
  new_fixes=()
  for f in "${fixes[@]}"; do
    IFS=, read -r fx fy <<< "$f"
    ((fx--))
    if (( fx <= 0 )); then continue; fi  # off screen
    # check collision
    if (( fx == x_pos && fy == y_pos )); then
      #((lives--))
      echo -e "${RED}Bash Challenge${RESET}"
      challenge_round
      sleep 0.5
    else
      new_fixes+=("$fx,$fy")
    fi
  done
  fixes=("${new_fixes[@]}")
}

spawn_error() {
  local ex=$((RANDOM % (${#map[0]} - 2) + 1))
  local ey=$((RANDOM % (${#map[@]} - 2) + 1))
  errors+=("$ex,$ey")
}

move_errors() {
  new_errors=()
  for e in "${errors[@]}"; do
    IFS=, read -r ex ey <<< "$e"
    ((ex--))
    if (( ex <= 0 )); then continue; fi  # off screen
    # check collision
    if (( ex == x_pos && ey == y_pos )); then
      ((lives--))
      echo -e "${RED}💥 You got hit by an error!${RESET}"
      sleep 0.5
    else
      new_errors+=("$ex,$ey")
    fi
  done
  errors=("${new_errors[@]}")
}

###################################
##       CHALLENGE SYSTEM        ##
###################################

# Tiered Challenge Pools
CHALLENGES_BEGINNER=(
  "ls"
  "pwd"
  "echo hello world"
  "mkdir testdir"
  "touch test.txt"
  "rm test.txt"
  "cd /tmp"
  "ls -l"
  "cat /etc/hostname"
  "whoami"
  "date"
  "mkdir -p mydir/subdir"
  "rmdir mydir/subdir"
  "echo 'Bash Game!' > game.txt"
  "cat game.txt"
  "rm game.txt"
  "cp /etc/hosts ./hosts_backup"
  "mv hosts_backup hosts.bak"
  "chmod 644 hosts.bak"
  "ls -a"
)

CHALLENGES_SYSADMIN=(
  "uname -a"
  "hostname"
  "hostnamectl"
  "uptime"
  "cat /etc/os-release"
  "lsb_release -a"
  "df -h"
  "du -sh /var/log"
  "ls -l /etc"
  "ls -lh /home"
  "find /home -type f -name '*.conf'"
  "stat /etc/passwd"
  "file /bin/bash"
  "mount | column -t"
  "who"
  "w"
  "last"
  "id $(whoami)"
  "groups $(whoami)"
  "cat /etc/passwd | grep /bin/bash"
  "getent passwd"
  "ps aux | grep ssh"
  "top -n 1"
  "htop"
  "pgrep bash"
  "pkill -n sleep"
  "systemctl status sshd"
  "ping -c 3 8.8.8.8"
  "ip a"
  "ifconfig -a"
  "netstat -tuln"
  "ss -tuln"
  "curl -I http://localhost"
  "traceroute 8.8.8.8"
  "dig example.com"
  "journalctl -n 20"
  "tail -f /var/log/syslog"
  "dmesg | tail -n 20"
  "chmod 644 /tmp/testfile"
  "chown $(whoami):$(whoami) /tmp/testfile"
  "ls -l /tmp/testfile"
  "tar -cvf archive.tar /tmp/testfile"
  "tar -xvf archive.tar"
  "gzip /tmp/testfile"
  "gunzip /tmp/testfile.gz"
  "apt list --installed"
  "dpkg -l | grep bash"
  "yum list installed"
  "dnf list installed"
  "echo 'Hello SysAdmin!' > /tmp/testfile"
  "cat /tmp/testfile"
  "rm /tmp/testfile"
  "date"
  "cal"
)


CHALLENGES_HACKER=(
  "ps aux | grep ssh"
  "find / -name '*.conf' 2>/dev/null | head -n 10"
  "netstat -tuln"
  "ss -tulnpa"
  "lsof -i -P -n"
  "tcpdump -nn -c 10 -i any"
  "tcpdump -r capture.pcap -n"
  "tshark -r capture.pcap -T fields -e ip.src -e ip.dst | sort | uniq -c"
  "nmap -sV -Pn 127.0.0.1"
  "nmap -sC -sV --script=vuln 127.0.0.1"
  "curl -I https://example.com"
  "openssl s_client -connect example.com:443 -showcerts"
  "dig +short example.com"
  "dig ANY example.com"
  "host -a example.com"
  "whois example.com"
  "traceroute -n 8.8.8.8"
  "mtr --report 8.8.8.8"
  "ip a"
  "ip route show"
  "ip -s link"
  "ethtool eth0"
  "arp -an"
  "route -n"
  "arpwatch -f /var/log/arpwatch.log"    # (read-only style)
  "awk '/error|fail/ {print \$0}' /var/log/syslog | tail -n 20"
  "grep -i 'segfault' /var/log/* 2>/dev/null | head -n 10"
  "journalctl -u ssh -n 50"
  "journalctl --since '1 hour ago' | tail -n 50"
  "dmesg | tail -n 40"
  "strings /usr/bin/somebinary | head -n 20"
  "ldd /bin/ls"
  "readelf -h /bin/ls"
  "strace -p \$(pgrep -n bash) -c -o /tmp/strace.out"  # (read-only usage pattern)
  "gdb -batch -ex 'info sharedlibrary' -ex quit /bin/ls"
  "ps aux --sort=-%mem | head -n 15"
  "top -b -n1 | head -n 20"
  "pgrep -a sshd"
  "pkill -n sleep"                            # (shows usage pattern)
  "ss -tunp | grep ESTAB"
  "iptables -L -n -v"
  "nft list ruleset"
  "journalctl --since 'yesterday' | grep -i ssh | wc -l"
  "awk '{if(NF>6) print \$1,\"->\",\$NF}' /proc/net/tcp | head -n 10"
  "cat /proc/net/tcp | awk '{print \$1,\$2,\$3}' | head -n 8"
  "nc -zv 127.0.0.1 22-1024"
  "nc -lvnp 1337"                             # (listening syntactic form)
  "openssl x509 -in cert.pem -noout -text | grep -i subject -A2"
  "git status -s"
  "git log --oneline --graph -n 10"
  "git diff --name-only origin/main"
  "docker ps -a --no-trunc"
  "docker images --format '{{.Repository}}:{{.Tag}} {{.Size}}' | head -n 10"
  "kubectl get pods -A"
  "kubectl describe pod mypod -n default"
  "aws s3 ls s3://mybucket --no-sign-request"
  "jq '.items[] | {name: .metadata.name}' file.json"
  "python -c 'import json,sys;print(json.load(sys.stdin)[0])' < file.json"
  "perl -0777 -ne 'print \"MATCH\\n\" if /password/' /var/www/* 2>/dev/null"
  "sed -n '1,50p' /etc/passwd"
  "awk -F: '{print \$1, \$6}' /etc/passwd | head -n 20"
  "find /var/log -type f -mtime -7 -print | wc -l"
  "rsync --dry-run -av /src/ /dst/ | head -n 10"
  "curl -sS http://localhost:8080/api/health | jq ."
  "openssl enc -d -aes-256-cbc -in secret.enc -pass pass:example"  # (illustrative)
  "hexdump -C /tmp/suspicious.bin | head -n 20"
  "xxd -g 1 -l 128 /tmp/suspicious.bin"
  "base64 -d <<< 'SGVsbG8sV29ybGQ='"
  "sudo journalctl -b --no-pager | head -n 40"
  "auditctl -l"
  "ausearch -m USER_LOGIN -ts today | tail -n 20"
  "ss -s"
  "nmcli device status"
  "iwconfig"
  "airmon-ng"                                 # monitoring concept
  "airmon-ng start wlan0"
  "tcpdump -nn -s0 -A -c 20 -i any port 80"
  "tshark -i any -Y 'http.request' -T fields -e http.host -c 10"
)

CHALLENGES_INTRUDER=(
  "ps aux | grep suspicious"
  "netstat -tuln"
  "ss -tuln"
  "kill $(pgrep -f malware)"
  "iptables -A INPUT -s 10.0.0.0/8 -j DROP"
  "systemctl stop sshd"
  "journalctl -xe | tail -n 20"
  "auditctl -l"
  "find /tmp -type f -name '*.sh' -exec rm -f {} \;"
  "chmod 700 /home/*/.ssh/authorized_keys"
  "chown root:root /etc/passwd"
  "cat /var/log/auth.log | grep 'Failed password'"
  "ufw status"
)

CHALLENGES_VIRUS=(
  "clamscan -r /tmp"
  "rm -f /tmp/suspicious*"
  "chkrootkit"
  "rkhunter --check"
  "systemctl stop malicious.service"
  "ps aux | grep malware"
  "iptables -A INPUT -s 0.0.0.0/0 -j DROP"
  "ufw enable"
)


# build master
CHALLENGES_MASTER=( "${CHALLENGES_BEGINNER[@]}" "${CHALLENGES_SYSADMIN[@]}" "${CHALLENGES_HACKER[@]}" )

# Fisher–Yates shuffle
for ((i=${#CHALLENGES_MASTER[@]}-1; i>0; i--)); do
  j=$((RANDOM % (i+1)))
  tmp=${CHALLENGES_MASTER[i]}
  CHALLENGES_MASTER[i]=${CHALLENGES_MASTER[j]}
  CHALLENGES_MASTER[j]=$tmp
done

get_difficulty_tier() {
  if ((score < 300)) || ((score == 300)); then
    echo "BEGINNER"
  elif ((score > 300)) && ((score < 700)); then
    echo "SYSADMIN"
  elif ((score > 700)) && ((score < 1000)); then
    echo "HACKER"
  else
    echo "MASTER"
  fi
}

# NEW CHALLENGE ROUND
CHALLENGE_START_LINE=$(( ${#map[@]} + 5 ))  # 5 lines for header

clear_challenge_panel() {
  for ((l=0; l<7; l++)); do
    printf "\033[%s;1H" "$((CHALLENGE_START_LINE + l))"
    printf "\033[2K"
  done
}

intruder_round() {
  clear_challenge_panel
  printf "\033[%s;1H" "$CHALLENGE_START_LINE"
  echo -e "${RED}🚨 INTRUDER ROUND! SysAdmin Challenge!${RESET}"
  
  local arr_name="CHALLENGES_INTRUDER[@]"
  local arr=("${!arr_name}")
  local intruder_commands=()
  
  local count=$(( 3 + score / 200 ))  # scale with score
  for _ in $(seq 1 $count); do
    intruder_commands+=("${arr[RANDOM % ${#arr[@]}]}")
  done
  # # pick 3 random commands
  # for _ in {1..3}; do
  #   intruder_commands+=("${arr[RANDOM % ${#arr[@]}]}")
  # done

  local start_time=$(date +%s)
  local total_time=15  # 15 seconds to complete all commands
  local success=1

  for cmd in "${intruder_commands[@]}"; do
    local remaining=$((total_time - ($(date +%s) - start_time)))
    if (( remaining <= 0 )); then
      success=0
      break
    fi

    echo -e "Execute within ${remaining}s: ${BLUE}${cmd}${RESET}"
    read -erp "> " user_input
    if [[ "$user_input" != "$cmd" ]]; then
      success=0
      break
    fi
  done

  # clear_challenge_panel
  if (( success )); then
    echo
    echo
    echo -e "${GREEN}✅ Intruder neutralized! +50 points${RESET}"
    ((score+=50))
    clear_challenge_panel
  else
    echo
    echo 
    echo -e "${RED}❌ Intruder breach! Lost 1 life${RESET}"
    ((lives--))
    clear_challenge_panel
  fi
  sleep 1

}


virus_round() {
  clear_challenge_panel
  printf "\033[%s;1H" "$CHALLENGE_START_LINE"
  echo -e "${YELLOW}🦠 VIRUS ROUND! Anti-Malware Challenge!${RESET}"

  local arr_name="CHALLENGES_VIRUS[@]"
  local arr=("${!arr_name}")
  local virus_commands=()
  for _ in {1..3}; do
    virus_commands+=("${arr[RANDOM % ${#arr[@]}]}")
  done

  local start_time=$(date +%s)
  local total_time=20  # slightly longer for malware defense
  local success=1

  for cmd in "${virus_commands[@]}"; do
    local remaining=$((total_time - ($(date +%s) - start_time)))
    if (( remaining <= 0 )); then
      success=0
      break
    fi
    echo -e "Execute within ${remaining}s: ${BLUE}${cmd}${RESET}"
    read -erp "> " user_input
    if [[ "$user_input" != "$cmd" ]]; then
      success=0
      break
    fi
  done

  
  if (( success )); then
    echo -e "${GREEN}✅ Virus neutralized! +70 points${RESET}"
    ((score+=70))
    sleep 1
    clear_challenge_panel
  else
    echo -e "${RED}❌ Virus infection! Lost 1 life${RESET}"
    ((lives--))
    sleep 1
    clear_challenge_panel
  fi
  
  
}

challenge_round() {
  clear_challenge_panel

  local tier=$(get_difficulty_tier)
  local arr_name="CHALLENGES_${tier}[@]"
  local arr=("${!arr_name}")
  local index=$((RANDOM % ${#arr[@]}))
  local cmd="${arr[$index]}"

  printf "\033[%s;1H" "$CHALLENGE_START_LINE"
  echo -e "${YELLOW}Micro Challenge — ${tier} Tier!${RESET}"
  echo -e "Type this command exactly:\n  ${BLUE}${cmd}${RESET}"

  # Timer start
  local start_time=$(date +%s)
  read -erp "> " user_input
  local end_time=$(date +%s)
  local elapsed=$((end_time - start_time))

  clear_challenge_panel
  printf "\033[%s;1H" "$CHALLENGE_START_LINE"
  if [[ "$user_input" == "$cmd" ]]; then
    local bonus=0
    if ((elapsed < 2)); then bonus=15; fi
    if ((elapsed < 5 && elapsed >= 2)); then bonus=5; fi
    local points=$((10 + bonus))
    ((score += points))
    echo -e "${GREEN}✅ Correct!${RESET} +${points} points  (in ${elapsed}s)"
  else
    echo -e "${RED}❌ Wrong command!${RESET} A process crashed!"
    echo -e "${RED}Expected:${RESET} $cmd"
    ((lives--))
  fi
  sleep 1
}

#######

###################################
##             LOOP              ##
###################################

render_map
while (( lives > 0 )); do
  ((tick++))
  
  compute_divisors
  (( RANDOM % error_divisor == 0 )) && spawn_error
  (( RANDOM % fix_divisor  == 0 )) && spawn_fixes

  # intruder spawn
  if (( score > 300 )); then
    (( RANDOM % 8 == 0 )) && spawn_intruder   # spawn chance per tick
  fi
  
  # virus spawn
  if (( score > 100 )); then
    (( RANDOM % 10 == 0 )) && spawn_virus
  fi

# move viruses in each tick
move_viruses


  # old spawn   ####################################
  #((tick % $ERROR_SPAWN_RATE == 0)) && spawn_error
  #((tick % $FIX_SPAWN_RATE == 0)) && spawn_fixes
  ##################################################
  move_fixes
  move_errors
  move_intruders
  render_map  # optimized version
  echo
  echo "(WASD to move, Q to quit)"
  read -rsn1 -t 0.2 input
  case "$input" in
    w) ((y_pos>1)) && ((y_pos--)) ;;
    s) ((y_pos<${#map[@]}-2)) && ((y_pos++)) ;;
    a) ((x_pos>1)) && ((x_pos<${#map[0]}-2)) && ((x_pos--)) ;;
    d) ((x_pos<${#map[0]}-2)) && ((x_pos++)) ;;
    q) echo "Bye!"; exit ;;
  esac
done


