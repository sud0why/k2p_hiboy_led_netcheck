#!/bin/sh
checkip="119.29.29.29"

checkled() {
    if [ 0 == $(mtk_gpio -r $1 | awk -F '= ' '{print $2}') ]; then
        #echo "on"
        return 1
    else
        #echo "off"
        return 0
    fi
}

logger "init led"
mtk_gpio -d 13 1
mtk_gpio -w 13 0
mtk_gpio -d 14 1
mtk_gpio -w 14 0
mtk_gpio -d 15 1
mtk_gpio -w 15 1

logger "init NetCheck"
for k in $(seq 1 11); do
    ping_text=$(ping -4 $checkip -c 1 -w 2 -W 2 -q)
    ping_time=$(echo $ping_text | awk -F '/' '{print $4}' | awk -F '.' '{print $1}')
    ping_loss=$(echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}')
    if [ ! -z "$ping_time" ]; then
        logger "[NetCheck] ping: $ping_time ms loss: $ping_loss"
        mtk_gpio -w 14 1
        mtk_gpio -w 15 0
    else
        logger "[NetCheck] ping: Failed"
        mtk_gpio -w 15 1
        mtk_gpio -w 14 0
    fi
    sleep 6
done

sleep 10

logger "Start Always Check"
while true; do
    ping_text=$(ping -4 $checkip -c 1 -w 2 -W 2 -q)
    ping_time=$(echo $ping_text | awk -F '/' '{print $4}' | awk -F '.' '{print $1}')
    ping_loss=$(echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}')
    if [ ! -z "$ping_time" ]; then
        if checkled 15; then
            logger "[NetCheck] ping: $ping_time ms loss: $ping_loss"
            mtk_gpio -w 14 1
            mtk_gpio -w 15 0
        fi
    else
        if checkled 14; then
            logger "[NetCheck] ping: Failed"
            mtk_gpio -w 15 1
            mtk_gpio -w 14 0
        fi
    fi
    sleep 10
done
