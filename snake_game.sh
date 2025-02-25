#!/bin/bash

ROWS=20
COLS=40
SNAKE=("$((ROWS / 2)),$((COLS / 2))")
FOOD=""
SPECIAL_FOOD=""
DIRECTION="RIGHT"
SCORE=0
SPEED=0.2
HARD_WALL=false
SPECIAL_TIMER=0
GAME_RUNNING=true
DIFFICULTY=""

C_GREEN="\e[32m"
C_YELLOW="\e[33m"
C_RED="\e[31m"
C_BLUE="\e[34m"
C_MAGENTA="\e[35m"
C_CYAN="\e[36m"
C_RESET="\e[0m"
C_BOLD="\e[1m"

select_difficulty() {
    clear
    echo -e "${C_BOLD}${C_CYAN}🐍 SNAKE GAME 🐍${C_RESET}\n"
    echo -e "${C_BOLD}Select Difficulty:${C_RESET}"
    echo -e "${C_GREEN}1) Easy${C_RESET}   - Slow speed, walls don't kill you"
    echo -e "${C_YELLOW}2) Medium${C_RESET} - Medium speed, walls don't kill you"
    echo -e "${C_RED}3) Hard${C_RESET}   - Fast speed, hitting walls is game over"
    echo -e "${C_MAGENTA}4) Expert${C_RESET} - Very fast speed, hitting walls is game over"
    echo ""
    
    echo -e "Enter your choice ${C_BOLD}[${C_GREEN}1${C_RESET}${C_BOLD}/${C_YELLOW}2${C_RESET}${C_BOLD}/${C_RED}3${C_RESET}${C_BOLD}/${C_MAGENTA}4${C_RESET}${C_BOLD}]:${C_RESET} "
    stty echo
    read choice
    stty -echo
    
    case $choice in
        1) 
            DIFFICULTY="Easy"
            SPEED=0.2
            HARD_WALL=false
            echo -e "\nYou selected: ${C_GREEN}Easy${C_RESET}"
            ;;
        2) 
            DIFFICULTY="Medium"
            SPEED=0.15
            HARD_WALL=false
            echo -e "\nYou selected: ${C_YELLOW}Medium${C_RESET}"
            ;;
        3) 
            DIFFICULTY="Hard"
            SPEED=0.1
            HARD_WALL=true
            echo -e "\nYou selected: ${C_RED}Hard${C_RESET}"
            ;;
        4) 
            DIFFICULTY="Expert"
            SPEED=0.07
            HARD_WALL=true
            echo -e "\nYou selected: ${C_MAGENTA}Expert${C_RESET}"
            ;;
        *) 
            DIFFICULTY="Medium"
            SPEED=0.15
            HARD_WALL=false
            echo -e "\nInvalid choice. Defaulting to: ${C_YELLOW}Medium${C_RESET}"
            ;;
    esac
    
    sleep 1.5
}

show_rules() {
    clear
    echo -e "${C_BOLD}${C_CYAN}🐍 WELCOME TO THE SNAKE GAME! 🐍${C_RESET}\n"
    echo -e "${C_BOLD}Rules:${C_RESET}"
    echo -e "- Use ${C_BOLD}'WASD'${C_RESET} keys to move:"
    echo -e "  ${C_GREEN}W${C_RESET} - Up"
    echo -e "  ${C_GREEN}A${C_RESET} - Left"
    echo -e "  ${C_GREEN}S${C_RESET} - Down"
    echo -e "  ${C_GREEN}D${C_RESET} - Right"
    echo -e "- Eat ${C_RED}🍎${C_RESET} to gain 1 point"
    echo -e "- Eat ${C_YELLOW}⭐${C_RESET} (special food) for 5 bonus points"
    
    if $HARD_WALL; then
        echo -e "- ${C_RED}Avoid hitting the walls${C_RESET}"
    fi
    
    echo -e "- Avoid hitting yourself"
    echo -e "- Press ${C_BOLD}'P'${C_RESET} to pause"
    echo -e "- Press ${C_BOLD}'Q'${C_RESET} to quit\n"
    echo -e "${C_BOLD}Difficulty:${C_RESET} ${DIFFICULTY}"
    echo -e "\nPress any key to start the game..."
    
    stty echo
    read -rsn1
    stty -echo
}

cleanup() {
    tput cnorm
    stty echo
    clear
    echo -e "${C_BOLD}${C_CYAN}Game Over!${C_RESET} ${C_BOLD}Final Score: ${SCORE}${C_RESET}"
    echo -e "Difficulty: ${DIFFICULTY}"
    exit
}

draw_board() {
    tput cup 0 0
    
    for ((i = 0; i < ROWS; i++)); do
        for ((j = 0; j < COLS; j++)); do
            if (( i == 0 || i == ROWS - 1 || j == 0 || j == COLS - 1 )); then
                echo -ne "${C_BLUE}#${C_RESET}"
            elif [[ "$i,$j" == "${SNAKE[0]}" ]]; then
                echo -ne "${C_GREEN}🐍${C_RESET}"
            elif [[ " ${SNAKE[*]:1} " =~ " $i,$j " ]]; then
                echo -ne "${C_GREEN}○${C_RESET}"
            elif [[ "$FOOD" == "$i,$j" ]]; then
                echo -ne "${C_RED}🍎${C_RESET}"
            elif [[ "$SPECIAL_FOOD" == "$i,$j" ]]; then
                echo -ne "${C_YELLOW}⭐${C_RESET}"
            else
                echo -n " "
            fi
        done
        echo ""
    done
    
    echo -e "Score: ${C_BOLD}${SCORE}${C_RESET} | Mode: ${C_BOLD}${DIFFICULTY}${C_RESET} | Speed: ${C_BOLD}$(printf "%.2f" $SPEED)${C_RESET}"
    if [[ -n "$SPECIAL_FOOD" ]]; then
        echo -e "Special Food Timer: ${C_YELLOW}${SPECIAL_TIMER}${C_RESET}"
    fi
}

generate_food() {
    local food
    while true; do
        food="$((RANDOM % (ROWS - 2) + 1)),$((RANDOM % (COLS - 2) + 1))"
        if [[ ! " ${SNAKE[*]} " =~ " $food " && "$food" != "$SPECIAL_FOOD" ]]; then
            FOOD="$food"
            break
        fi
    done
}

generate_special_food() {
    local food
    while true; do
        food="$((RANDOM % (ROWS - 2) + 1)),$((RANDOM % (COLS - 2) + 1))"
        if [[ ! " ${SNAKE[*]} " =~ " $food " && "$food" != "$FOOD" ]]; then
            SPECIAL_FOOD="$food"
            SPECIAL_TIMER=50
            break
        fi
    done
}

move_snake() {
    local head="${SNAKE[0]}"
    local new_head=()

    IFS=',' read -ra head_pos <<< "$head"
    local row=${head_pos[0]}
    local col=${head_pos[1]}

    case $DIRECTION in
        UP)    row=$((row - 1));;
        DOWN)  row=$((row + 1));;
        LEFT)  col=$((col - 1));;
        RIGHT) col=$((col + 1));;
    esac

    if (( row <= 0 || row >= ROWS-1 || col <= 0 || col >= COLS-1 )); then
        if $HARD_WALL; then
            cleanup
        else
            if (( row <= 0 )); then row=$((ROWS - 2)); fi
            if (( row >= ROWS-1 )); then row=1; fi
            if (( col <= 0 )); then col=$((COLS - 2)); fi
            if (( col >= COLS-1 )); then col=1; fi
        fi
    fi

    new_head="${row},${col}"

    for segment in "${SNAKE[@]}"; do
        if [[ "$segment" == "$new_head" ]]; then
            cleanup
        fi
    done

    SNAKE=("$new_head" "${SNAKE[@]}")

    if [[ "$new_head" == "$FOOD" ]]; then
        generate_food
        SCORE=$((SCORE + 1))
        
        if (( $(echo "$SPEED > 0.05" | bc -l) )); then
            SPEED=$(echo "$SPEED - 0.005" | bc -l)
        fi
    elif [[ "$new_head" == "$SPECIAL_FOOD" ]]; then
        SPECIAL_FOOD=""
        SPECIAL_TIMER=0
        SCORE=$((SCORE + 5))
        
        if (( $(echo "$SPEED > 0.05" | bc -l) )); then
            SPEED=$(echo "$SPEED - 0.01" | bc -l)
        fi
    else
        SNAKE=("${SNAKE[@]:0:${#SNAKE[@]}-1}")
    fi
}

read_input() {
    read -rsn1 -t 0.01 key
    if [[ -n "$key" ]]; then
        case $key in
            w|W) [[ "$DIRECTION" != "DOWN" ]] && DIRECTION="UP";;
            s|S) [[ "$DIRECTION" != "UP" ]] && DIRECTION="DOWN";;
            a|A) [[ "$DIRECTION" != "RIGHT" ]] && DIRECTION="LEFT";;
            d|D) [[ "$DIRECTION" != "LEFT" ]] && DIRECTION="RIGHT";;
            p|P) pause_game;;
            q|Q) cleanup;;
        esac
    fi
}

pause_game() {
    local old_setting=$(stty -g)
    stty echo
    tput cnorm
    echo -e "\n${C_BOLD}Game Paused.${C_RESET} Press any key to resume or 'Q' to quit."
    read -rsn1 key
    if [[ "$key" == "q" || "$key" == "Q" ]]; then
        cleanup
    fi
    tput civis
    stty "$old_setting"
}

tput civis
trap cleanup EXIT INT

select_difficulty
show_rules

clear
generate_food
draw_board

while $GAME_RUNNING; do
    read_input
    sleep $SPEED
    move_snake
    
    if [[ $SPECIAL_TIMER -gt 0 ]]; then
        SPECIAL_TIMER=$((SPECIAL_TIMER - 1))
        if [[ $SPECIAL_TIMER -eq 0 ]]; then
            SPECIAL_FOOD=""
        fi
    elif [[ $((RANDOM % 25)) -eq 0 && -z $SPECIAL_FOOD ]]; then
        generate_special_food
    fi

    draw_board
done
