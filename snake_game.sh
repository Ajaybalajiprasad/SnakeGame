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

cleanup() {
    tput cnorm
    clear
    echo "Game Over! Final Score: $SCORE"
    exit
}

draw_board() {
    tput cup 0 0
    for ((i = 0; i < ROWS; i++)); do
        for ((j = 0; j < COLS; j++)); do
            if (( i == 0 || i == ROWS - 1 || j == 0 || j == COLS - 1 )); then
                echo -n "#"
            elif [[ "$i,$j" == "${SNAKE[0]}" ]]; then
                echo -n "🐲" # Snake head
            elif [[ " ${SNAKE[*]:1} " =~ " $i,$j " ]]; then
                echo -n "O" # Snake body
            elif [[ "$FOOD" == "$i,$j" ]]; then
                echo -n "🍎" # Regular food
            elif [[ "$SPECIAL_FOOD" == "$i,$j" ]]; then
                echo -n "⭐" # Special food
            else
                echo -n " "
            fi
        done
        echo ""
    done
    echo "Score: $SCORE | Speed: $SPEED | Special Food Timer: $SPECIAL_TIMER"
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
            SPECIAL_TIMER=50  # Increased timer for longer visibility
            break
        fi
    done
}

move_snake() {
    local head="${SNAKE[0]}"
    local new_head=()

    IFS=',' read -ra head_pos <<< "$head"

    case $DIRECTION in
        UP)    new_head=("$((head_pos[0] - 1))" "${head_pos[1]}");;
        DOWN)  new_head=("$((head_pos[0] + 1))" "${head_pos[1]}");;
        LEFT)  new_head=("${head_pos[0]}" "$((head_pos[1] - 1))");;
        RIGHT) new_head=("${head_pos[0]}" "$((head_pos[1] + 1))");;
    esac

    if $HARD_WALL; then
        if (( new_head[0] < 0 || new_head[0] >= ROWS || new_head[1] < 0 || new_head[1] >= COLS )); then
            cleanup
        fi
    else
        if (( new_head[0] < 0 )); then
            new_head[0]=$((ROWS - 2))
        elif (( new_head[0] >= ROWS - 1 )); then
            new_head[0]=1
        fi

        if (( new_head[1] < 0 )); then
            new_head[1]=$((COLS - 2))
        elif (( new_head[1] >= COLS - 1 )); then
            new_head[1]=1
        fi
    fi

    new_head="${new_head[0]},${new_head[1]}"

    # Check for collision with the body
    if [[ " ${SNAKE[*]:1} " =~ " $new_head " ]]; then
        cleanup
    fi

    SNAKE=("$new_head" "${SNAKE[@]}")

    if [[ "$new_head" == "$FOOD" ]]; then
        generate_food
        SCORE=$((SCORE + 1))
        SPEED=$(awk "BEGIN {print $SPEED - 0.01}")
    elif [[ "$new_head" == "$SPECIAL_FOOD" ]]; then
        SPECIAL_FOOD=""
        SPECIAL_TIMER=0
        SCORE=$((SCORE + 5))
        SPEED=$(awk "BEGIN {print $SPEED - 0.02}")
    else
        SNAKE=("${SNAKE[@]:0:${#SNAKE[@]}-1}")
    fi
}

change_direction() {
    read -rsn1 -t "$SPEED" key
    case $key in
        w) [[ "$DIRECTION" != "DOWN" ]] && DIRECTION="UP";;
        s) [[ "$DIRECTION" != "UP" ]] && DIRECTION="DOWN";;
        a) [[ "$DIRECTION" != "RIGHT" ]] && DIRECTION="LEFT";;
        d) [[ "$DIRECTION" != "LEFT" ]] && DIRECTION="RIGHT";;
        p) pause_game;;
    esac
}

pause_game() {
    read -rsn1 -p "Game Paused. Press any key to resume." key
}

tput civis
trap cleanup EXIT

clear
generate_food
draw_board

while true; do
    change_direction
    move_snake
    
    if [[ $SPECIAL_TIMER -gt 0 ]]; then
        SPECIAL_TIMER=$((SPECIAL_TIMER - 1))
        if [[ $SPECIAL_TIMER -eq 0 ]]; then
            SPECIAL_FOOD=""
        fi
    elif [[ $((RANDOM % 20)) -eq 0 && -z $SPECIAL_FOOD ]]; then
        generate_special_food
    fi

    draw_board
done
