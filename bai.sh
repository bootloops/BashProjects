#!/bin/bash
# BaiSH: Ultimate Professional Bash AI with Local Ollama + Command Dictionary
# Features:
# - Strict command-only responses
# - Session memory
# - Relevant command info from auto_dictionary.json
# - Safe JSON escaping
# - Robust syntax highlighting using awk
# - Ctrl+C handling
# - Multi-line input support

# SIMPLE COLORS
RESET="\033[0m"

CYAN="\033[36m"
GREEN="\033[32m"
BLACK="\033[30m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
WHITE="\033[37m"

# Bright (bold)
BRIGHT_BLACK="\033[90m"
BRIGHT_RED="\033[91m"
BRIGHT_GREEN="\033[92m"
BRIGHT_YELLOW="\033[93m"
BRIGHT_BLUE="\033[94m"
BRIGHT_MAGENTA="\033[95m"
BRIGHT_CYAN="\033[96m"
BRIGHT_WHITE="\033[97m"

# BACKGROUND COLORS
# Standard Background Colors
BG_BLACK="\033[40m"
BG_RED="\033[41m"
BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
BG_BLUE="\033[44m"
BG_MAGENTA="\033[45m"
BG_CYAN="\033[46m"
BG_WHITE="\033[47m"

# Bright Background Colors
BG_BRIGHT_BLACK="\033[100m"   # Gray / Dark Gray
BG_BRIGHT_RED="\033[101m"
BG_BRIGHT_GREEN="\033[102m"
BG_BRIGHT_YELLOW="\033[103m"
BG_BRIGHT_BLUE="\033[104m"
BG_BRIGHT_MAGENTA="\033[105m"
BG_BRIGHT_CYAN="\033[106m"
BG_BRIGHT_WHITE="\033[107m"


# PREFERENCES
MODEL="phi3"
DICTIONARY_JSON="./auto_dictionary.json"

#DEBUG ON/OFF (1/0)
DEBUG=0

#OLLAMA API
OLLAMA_URL="http://localhost:11434/v1/completions"

# TEST IF OLLAMA SERVER RUNNING
# TEST IF OLLAMA SERVER RUNNING
if curl -s http://localhost:11434/ >/dev/null 2>&1; then
    AI_ON="Ollama running."
else
    AI_ON="Ollama not running."
fi

#HISTORY
HISTFILE=~/.baish_history
HISTSIZE=1000
HISTFILESIZE=2000

# Create file if it doesn’t exist
touch "$HISTFILE"
history -r

#DEBUG FUNCTION
debug() {
    if [[ "$DEBUG" -eq 1 ]]; then
        echo -e "[DEBUG=$DEBUG]"
        echo -e "[DEBUG-AI] $AI_ON"
        echo -e "[DEBUG] $*"
    fi
}

#TERMINAL COLOR SUPPORT CHECK
supports_256_colors() {
  case "$TERM" in
    *256color*) debug "256colors supported"; return 0 ;;  # most common
    xterm|screen|linux) debug "256colors not supported, using 16 colors"; return 1 ;; # likely 16-color
    *) debug "unknown support; using 16 colors"; return 1 ;;
  esac
}
supports_256_colors


# Check dictionary exists
#if [[ ! -f "$DICTIONARY_JSON" ]]; then
#    echo "⚠ Dictionary not found. Run dictionary_generator.py first."
    #python dictionary_generator.py
#    exit 1
#fi



#DEFAULT CONTEXT
DEFAULT_CONTEXT="Act as a Linux/Bash Master Guru mentoring an apprentice.
Respond ONLY with valid Bash commands or terminal instructions.
No explanations, no examples, no commentary, no formatting, no emojis.
Output must be plain commands only.
If no valid command exists, return nothing."

INFO_CONTEXT="Act as a Linux/Bash Master Guru mentoring an apprentice.
Respond with precise Bash commands or terminal instructions.
Always include a brief explanation and one working example.
No commentary, emojis, or formatting.
Keep explanations minimal and commands correct."


SEARCH_CONTEXT="Act as a Linux/Bash Master Guru mentoring an apprentice.
Provide Bash commands or terminal instructions that help the user locate information.
If possible, give the direct command or result.
If not certain, suggest reliable resources or next steps.
Keep responses short, precise, and actionable."

# Awk-based highlighter
highlight() {
    awk -v GREEN="\033[32m" -v YELLOW="\033[33m" \
        -v BLUE="\033[34m" -v CYAN="\033[36m" -v RESET="\033[0m" '
    {
        $1 = GREEN $1 RESET
        gsub(/ -[a-zA-Z0-9]+/, YELLOW "&" RESET)
        gsub(/\/[a-zA-Z0-9_\/\.\-]+/, BLUE "&" RESET)
        gsub(/\$[a-zA-Z0-9_]+/, CYAN "&" RESET)
        print
    }'
}

# Extract relevant commands from dictionary based on user query
#version3
get_relevant_commands() {
    local query="$1"
    local max_results=7

    # stop words
    #local stop_words="^(how|to|the|a|an|please|start|run|open|show|which|what|is|are|do|you|i|my|on|in|of|for|and|or|with|use)$"
    local stop_words="^(to|the|a|an|please|start|run|open|are|do|you|i|my|on|in|of|for|and|or|with|use)$"

    # tokenize user query
    IFS=$'\n' tokens=($(echo "$query" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9_]+/ /g' \
        | xargs -n1 echo \
        | awk 'length($0) >= 2' \
        | grep -Ev "$stop_words" || true))

    [[ ${#tokens[@]} -eq 0 ]] && return 0

    # build regex from tokens
    local regex=""
    for t in "${tokens[@]}"; do
        esc=$(printf '%s' "$t" | sed -E 's/[][^$.*/\\+?(){}|]/\\&/g')
        [[ -z "$regex" ]] && regex="$esc" || regex="$regex|$esc"
    done

    debug "tokens=(${tokens[*]})"
    debug "query_regex=$regex"

    # jq: return title, description, and example
    jq -r --arg q "$regex" --argjson max "$max_results" '
      map(
        { title, description, example,
          score: (
            (if (.title|ascii_downcase) | test($q) then 1 else 0 end) * 10 +
            (if (.description|ascii_downcase) | test($q) then 1 else 0 end) * 3
          )
        }
      )
      | map(select(.score>0))
      | unique_by(.title)
      | sort_by(.score) | reverse
      | .[0:$max][]
      | "\(.title): \(.description)\n    Example: \(.example)"
    ' "$DICTIONARY_JSON"
}

# Track background commands
CURRENT_PID=""

run_command() {
    local cmd="$1"
    eval "$cmd" &
    CURRENT_PID=$!
    wait $CURRENT_PID
    CURRENT_PID=""
}

trap "if [[ -n \"$CURRENT_PID\" ]]; then kill -INT $CURRENT_PID 2>/dev/null; fi; echo -e \"\n${CYAN}^C Command interrupted${RESET}\"" INT

# SYSTEM INFO
USER_NAME=$(whoami)
HOST_NAME=$(hostname)
UPTIME_INFO=$(uptime -p)
MEMORY_INFO=$(free -h | awk '/Mem:/ {print $3 " used / " $2 " total"}')
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ //')

# HEADER FUNCTION
show_header() {
    clear
    echo -e "\t${CYAN}██████     ${WHITE}▄▄▄▄    ▄▄${CYAN}  ▒██████  ██░ ██ ${RESET}"
    echo -e "\t${CYAN}▓█   ▒▄  ▒${WHITE}██  ▒█▄    ${CYAN} ▒██    ▒ ▓██░ ██▒${RESET}"
    echo -e "\t${CYAN}▒█████▄    ${WHITE}▄▄▄▒█▄ ▒██${CYAN}▒░ ▓██▄   ▒██▀▀██░${RESET}"
    echo -e "\t${CYAN}▒▓█   ▒▄ ░${WHITE}██  ▒██ ░██${CYAN}░  ▒   ██▒░▓█ ░██ ${RESET}"
    echo -e "\t${CYAN}░▒████▒ ░${WHITE}██▄▄▄▓██▒░██${CYAN}░▒██████▒▒░▓█▒░██▓${RESET}"
    echo -e "\t${CYAN}░░ ${RESET}${GREEN}▒░ ░  ▒▒   ${RESET}${GREEN}▓▒█░░▓  ▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒${RESET}"
    echo -e "\t${CYAN} ░ ░  ░   ▒   ▒▒ ░ ▒ ░░ ░▒  ░ ░ ▒ ░▒░ ░${RESET}"
    echo -e "\t${CYAN}   ░      ${RESET}${GREEN}░   ▒    ▒ ░░  ░${RESET}${GREEN}  ░   ░  ░░ ░${RESET}"
    echo -e "\t${CYAN}   ${RESET}${GREEN}░  ░       ░  ░ ░        ░   ░  ░  ░${RESET}"
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│\t${RESET} User: ${YELLOW}${USER_NAME}${RESET} @ Host: ${YELLOW}${HOST_NAME}${RESET}                ${CYAN}│${RESET}"
    echo -e "${CYAN}│\t${RESET} AI Status: ${BRIGHT_GREEN}${AI_ON}${RESET}                    ${CYAN}│${RESET}"
    echo -e "${CYAN}│\t${RESET} Uptime: ${BRIGHT_MAGENTA}${UPTIME_INFO}${RESET}                ${CYAN}│${RESET}"
    echo -e "${CYAN}│\t${RESET} CPU Load:${BRIGHT_MAGENTA} ${CPU_LOAD} ${RESET}                   ${CYAN}│${RESET}"
    echo -e "${CYAN}│\t${RESET} Memory Usage:${BRIGHT_MAGENTA} ${MEMORY_INFO} ${RESET}        ${CYAN}│${RESET}"
    echo -e "${CYAN}│\t${RESET} Type 'exit' or 'quit' to leave.               ${CYAN}│${RESET}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${RESET}"
}


# Call the header
show_header

# CONTEXT
SESSION_PROMPT="$CONTEXT"

# Detect context from full input, not just first word
detect_context() {
    local input="$1"

    if [[ "$input" =~ \b(where|find|which|when)\b ]]; then
        CONTEXT=$SEARCH_CONTEXT
        debug "${CYAN}SEARCH CONTEXT${RESET}"
    elif [[ "$input" =~ \b(what|how|why)\b ]]; then
        CONTEXT=$INFO_CONTEXT
        debug "${CYAN}INFO CONTEXT${RESET}"
    else
        CONTEXT=$DEFAULT_CONTEXT
        debug "${CYAN}DEFAULT CONTEXT${RESET}"
    fi
}

# COMBINED MATRIX/GRAFFITI/NEON PS1
matrix_graffiti_neon() {
    # Colors to cycle through for the waterfall effect
    COLORS=($BRIGHT_GREEN $BRIGHT_CYAN $BRIGHT_YELLOW $BRIGHT_MAGENTA $BRIGHT_WHITE)
    
    local text="BaiSH"
    local styled="${BRIGHT_BLACK}B${BRIGHT_WHITE}ai${BRIGHT_BLACK}SH"

    #PS1="${BRIGHT_GREEN}▌${BRIGHT_CYAN} BaiSH ${RESET} ${BRIGHT_GREEN}| \w | ${BRIGHT_MAGENTA}>\u ❯ ${RESET}\n${BRIGHT_YELLOW} ❯ ${RESET}"
    # Multi-line Cyberpunk Prompt (Amplified)
    PS1="
    ${BG_CYAN}${BRIGHT_GREEN}▌ ${styled} ▌${BG_BLUE}${BRIGHT_CYAN} ${USER} ${BRIGHT_BLUE}▶ ${BG_MAGENTA}${BRIGHT_WHITE} $(pwd) ${BRIGHT_WHITE}▶ ${RESET} \n\
    ${BG_BRIGHT_BLACK}${BRIGHT_YELLOW} ⌬ Host:${BRIGHT_WHITE} ${HOSTNAME} ${BG_BRIGHT_BLACK}${BRIGHT_GREEN}▌ ${BRIGHT_WHITE}Uptime:${BRIGHT_CYAN} $(uptime -p) ${BG_BRIGHT_BLACK}${BRIGHT_RED}▌ ${BRIGHT_WHITE}CPU:${BRIGHT_GREEN} $(uptime | awk -F'load average:' '{print $2}') ${RESET} \n\
    ${BRIGHT_MAGENTA}❯ ${RESET} "

    echo -e "$PS1"
}


# Main loop
while true; do
    # Generate prompt string from your function
    PROMPT_STR=$(matrix_graffiti_neon)

    read -e -p "${PROMPT_STR}" USER_INPUT || { echo "👋 Exiting BaiSH..."; break; }

    # truncate to all lower
    #USER_INPUT=$(echo "$USER_INPUT" | tr '[:upper:]' '[:lower:]')

    CMD=${USER_INPUT%% *}   # first word
    ARGS=${USER_INPUT#* }   # everything after first word
    [[ -n "$USER_INPUT" ]] && history -s "$USER_INPUT" && history -a

    case "$CMD" in
        exit|quit|EXIT|QUIT)
            echo "👋 Exiting BaiSH..."
            break
            ;;
        *)
            detect_context $CMD
            ;;
        
    esac

    # Alternatively, using $ as a prefix:
    if [[ "$USER_INPUT" =~ ^\$[[:space:]]*(.+) ]]; then
        CMD_TO_RUN="${BASH_REMATCH[1]}"
        echo -e "${BRIGHT_CYAN}${BG_BLACK}Executing:${CYAN} $CMD_TO_RUN"
        eval "$CMD_TO_RUN"
        continue
    fi

    # Multi-line input
    while [[ "$USER_INPUT" =~ \\$ ]]; do
        read -p "> " NEXT_LINE
        USER_INPUT="${USER_INPUT%\\}$NEXT_LINE"
    done

    # 🔍 First, try dictionary lookup
    #RELEVANT_INFO=$(get_relevant_commands "$USER_INPUT")  #uncomment this if you want to use auto_dictionary.json

    # if [[ -n "$RELEVANT_INFO" ]]; then
    #     # If we found a dictionary entry, show it instantly (fast path)
    #     echo -e "\033[33m📖 From Dictionary:\033[0m"
    #     echo -e "$RELEVANT_INFO \t"
    #     continue
    # fi

    # 🧠 Otherwise, fall back to AI
    SESSION_PROMPT="$CONTEXT
User: $USER_INPUT
AI:"
    debug $SESSION_PROMPT

    ESCAPED_PROMPT=$(echo "$SESSION_PROMPT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')

    debug $ESCAPED_PROMPT

    RESPONSE=$(curl -s -X POST "$OLLAMA_URL" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$MODEL\", \"prompt\": $ESCAPED_PROMPT, \"max_tokens\": 200}")

    debug $RESPONSE

    AI_OUTPUT=$(echo "$RESPONSE" | jq -r '
        .response // 
        .completion // 
        .choices[0].text // 
        "No response."')

    AI_OUTPUT=$(echo "$AI_OUTPUT" | sed 's/^```.*$//g' | sed 's/^Assistant:.*$//g' | sed 's/^ai:.*$//g')
    AI_OUTPUT=$(echo "$AI_OUTPUT" | sed 's/^[ \t]*//;s/[ \t]*$//')

    echo "$AI_OUTPUT" | highlight


    
    #____________________________________________
    #---------- OPTIONAL ----------------
    #----- UNSAFE ------ CAUTION --------
    #-------- USE WITH FEAR -------------
    # Ask if user wants to run them
    #echo
    #echo "Do you want to run these commands? [y/N] "
    #read -r RUN_CONFIRM
    #if [[ "$RUN_CONFIRM" =~ ^[Yy]$ ]]; then
    #    echo "⚡ Executing AI-suggested commands..."
    #    while IFS= read -r line; do
    #        if [[ -n "$line" ]]; then
    #            echo "+ $line"
    #            eval "$line"
    #        fi
    #    done <<< "$AI_OUTPUT"
    #fi
    #____________________________________________|


    # UNCOMMENT BELOW IF YOU WANT PERSISTANT MEMORY
    # OF THE CONVERSATION -- Not required
    # Append AI response to session memory
    #SESSION_PROMPT="$SESSION_PROMPT $AI_OUTPUT" #--uncomment to enable

    # export ps1
    export PS1

done
