#!/bin/sh

PID=$( ps | grep [s]nort|cut -d' ' -f1)
LOG_FILE="Secom_FW1219_${PID}_CPU.csv"
#echo $PID
# 寫入 CSV 標頭
echo "Timestamp,PID_CPU_Usage(%)" > $LOG_FILE

# 獲取 CPU 核心數 (Embedded 環境通常可用 nproc 或 grep)
CPU_COUNT=$(grep -c ^processor /proc/cpuinfo)

# 初始讀取
get_stats() {
    # 獲取進程 utime + stime
    PROC_STAT=$(cat /proc/$PID/stat 2>/dev/null)
    [ -z "$PROC_STAT" ] && echo "0 0" && return
    UTIME=$(echo $PROC_STAT | cut -d' ' -f14)
    STIME=$(echo $PROC_STAT | cut -d' ' -f15)
    echo "$UTIME $STIME"
}

get_total_cpu() {
    # 獲取系統總 CPU Ticks
    grep '^cpu ' /proc/stat | awk '{sum=$2+$3+$4+$5+$6+$7+$8+$9; print sum}'
}

# 第一次取樣
PREV_PROC=$(get_stats)
PREV_TOTAL=$(get_total_cpu)

while true; do
    sleep 1

    # 第二次取樣
    CURR_PROC=$(get_stats)
    CURR_TOTAL=$(get_total_cpu)
    TS=$(date '+%H:%M:%S')

    # 解析數值
    P1_U=$(echo $PREV_PROC | cut -d' ' -f1)
    P1_S=$(echo $PREV_PROC | cut -d' ' -f2)
    P2_U=$(echo $CURR_PROC | cut -d' ' -f1)
    P2_S=$(echo $CURR_PROC | cut -d' ' -f2)

    # 計算差值 (Delta)
    DIFF_PROC=$(( (P2_U + P2_S) - (P1_U + P1_S) ))
    DIFF_TOTAL=$(( CURR_TOTAL - PREV_TOTAL ))

    # 計算百分比 (需考慮核心數)
    if [ $DIFF_TOTAL -gt 0 ]; then
        # 在 Shell 中使用整數運算，先乘 10000 再除以 100 得到兩位小數
        #IRIX Mode
        #USAGE_X100=$(( 100 * DIFF_PROC * 100 * CPU_COUNT / DIFF_TOTAL ))
        #Solaris Mode
        USAGE_X100=$(( 100 * DIFF_PROC * 100 / DIFF_TOTAL ))
        # 格式化輸出，例如 1234 變 12.34
        INTEGER=$(( USAGE_X100 / 100 ))
        FRACTION=$(( USAGE_X100 % 100 ))
        RESULT="$INTEGER.$FRACTION"
    else
        RESULT="0.00"
    fi

    echo "$TS,$RESULT" | tee -a $LOG_FILE

    # 更新舊值
    PREV_PROC=$CURR_PROC
    PREV_TOTAL=$CURR_TOTAL
done
