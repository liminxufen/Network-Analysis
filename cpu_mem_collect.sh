#!/bin/bash

#write by erichli

#输出为Json格式
function WriteOutJson() {
    #local all_params=($(echo $@))
    #echo ${all_params[@]}
    echo '{"metric": "'$1'","value":'$2'}'
}

#求出最大值
function find_max() {
    if [ $# -eq 0 ]; then
        return 0
    fi
    max=0
    for arg in $*
    do
       max=`echo $arg $max | awk '{if ($1>$2)print $1; else print $2}'`
    done
    echo $max
}

#统计CPU使用率
function Statistic_CPU_Ratio() {
    local cpu_count=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
    local max_cpu_used_ratio=0
    if [ -e cpu1.tmp ]; then
        rm cpu1.tmp
    fi
    if [ -e cpu2.tmp ]; then
        rm cpu2.tmp
    fi    
    if [ -e result.tmp ]; then
        rm result.tmp
    fi    
    if [[ -e each*.tmp ]]; then
        rm each*.tmp
    fi    
    for ((j=0; j<4; j++))
    do
        #计算cpu总揽
        cpu_be=(`cat /proc/stat | grep -w cpu | awk '{$1="";print $0}' | sed 's/^ *//'`)
        cpu_total_be=$[${cpu_be[1]}+${cpu_be[2]}+${cpu_be[3]}+${cpu_be[4]}+${cpu_be[5]}+${cpu_be[6]}+${cpu_be[7]}]
        cpu_used_be=$[${cpu_be[1]}+${cpu_be[2]}+${cpu_be[3]}+${cpu_be[6]}+${cpu_be[7]}]
        #计算每个cpu核
        for ((i=0; i<=$[$cpu_count-1]; i++))
        do
            c="cpu$i"
            echo `cat /proc/stat | grep -w $c | awk '{print $0}'` >> ./cpu1.tmp
            #cpu_be=(`cat /proc/stat | grep -w $c | awk -v cpu=$c '{$1="";print cpu, $0}'`)
        done    
  
        sleep 15 #休眠15秒

        #15s后再次计算cpu总揽
        cpu_af=(`cat /proc/stat | grep -w cpu | awk '{$1="";print $0}' | sed 's/^ *//'`)
        cpu_total_af=$[${cpu_be[1]}+${cpu_be[2]}+${cpu_be[3]}+${cpu_be[4]}+${cpu_be[5]}+${cpu_be[6]}+${cpu_be[7]}]
        cpu_used_af=$[${cpu_be[1]}+${cpu_be[2]}+${cpu_be[3]}+${cpu_be[6]}+${cpu_be[7]}]

        #echo $cpu_total_af $cpu_total_be $cpu_used_af $cpu_used_be
        if [ $cpu_total_af -eq $cpu_total_be ]; then
            cpu_used_ratio=0
        else    
            cpu_used_ratio=`echo $cpu_total_af $cpu_total_be $cpu_used_af $cpu_used_be | awk '{print ($3-$4)/($1-$2)*100}'`
        fi
        #if [ ${max_cpu_used_ratio%.*} -lt ${cpu_used_ratio%.*} ]; then
        max_cpu_used_ratio=`echo $max_cpu_used_ratio $cpu_used_ratio | awk '{if ($1>$2)print $1; else print $2}'`       
        #fi    

        #15s后再次计算每个cpu核
        for ((i=0; i<=$[$cpu_count-1]; i++))
        do
            c="cpu$i"
            echo `cat /proc/stat | grep -w $c | awk '{print $0}'` >> ./cpu2.tmp
            #cpu_af=(`cat /proc/stat | grep -w $c | awk -v cpu=$c '{$1="";print cpu, $0}'`)
        done
        #统计每个cpu核使用率
        for ((i=0; i<=$[$cpu_count-1]; i++))
        do
            c="cpu$i"
            #c_total_be=$(awk -v cpu=$c '{if($1 ~/^cpu$/){print ($2+$3+$4+$5+$6+$7+$8)}}' cpu1.tmp)
            #c_total_af=$(awk -v cpu=$c '{if($1 ~/^cpu$/){print ($2+$3+$4+$5+$6+$7+$8)}}' cpu2.tmp)
            #c_used_be=$(awk -v cpu=$c '{if($1 ~/^cpu$/){print ($2+$3+$4+$7+$8)}}' cpu1.tmp)
            #c_used_af=$(awk -v cpu=$c '{if($1 ~/^cpu$/){print ($2+$3+$4+$7+$8)}}' cpu2.tmp)
            c_total_be=$(cat cpu1.tmp | grep -w $c | awk '{print ($2+$3+$4+$5+$6+$7+$8)}')
            c_total_af=$(cat cpu2.tmp | grep -w $c | awk '{print ($2+$3+$4+$5+$6+$7+$8)}')
            c_used_be=$(cat cpu1.tmp | grep -w $c | awk '{print ($2+$3+$4+$7+$8)}')
            c_used_af=$(cat cpu2.tmp | grep -w $c | awk '{print ($2+$3+$4+$7+$8)}')
            #echo $c_total_af $c_total_be $c_used_af $c_used_be
            if [ $c_total_af -eq $c_total_be ]; then
                c_used_ratio=0
            else    
                c_used_ratio=`echo $c_total_af $c_total_be $c_used_af $c_used_be | awk '{print ($3-$4)/($1-$2)*100}'`
            fi    
            echo $c $c_used_ratio >> ./each$j.tmp
        done    

        rm cpu1.tmp 
        rm cpu2.tmp
    done
        #找出每个cpu核的最大使用率
        echo $max_cpu_used_ratio > ./result.tmp
        for ((i=0; i<=$[$cpu_count-1]; i++))
        do
            c="cpu$i"
            v1=`awk -v cpu=$c '{if($0 ~cpu){print $2}}' ./each0.tmp`
            v2=`awk -v cpu=$c '{if($0 ~cpu){print $2}}' ./each1.tmp`
            v3=`awk -v cpu=$c '{if($0 ~cpu){print $2}}' ./each2.tmp`
            v4=`awk -v cpu=$c '{if($0 ~cpu){print $2}}' ./each3.tmp`
            echo $(find_max $v1 $v2 $v3 $v4) >> ./result.tmp
        done    
        awk '{print $1}' ./result.tmp | sed '{:a N;s/\n/ /;b a}'
        rm result.tmp
        rm each*.tmp
}


#统计内存使用量
function Statistic_MEM() {
    local mem_total=`free -m | awk '{if($0~"Mem")print $2}'`
    local mem_used=`free -m | awk '{if($0~"Mem")print $3}'`
    local app_mem_used=`free -m | grep -w 'buffers/cache' | awk '{print $3}'`
    if [ -z "$app_mem_used" ]; then
	app_mem_used=0
    fi
    local mem_used_ratio=`echo $mem_used $mem_total | awk '{print ($1/$2)*100}'
    local app_mem_used_ratio=`echo $app_mem_used $mem_total | awk '{print ($1/$2)*100}'`
    echo $mem_total $mem_used $app_mem_used $mem_used_ratio $app_mem_used_ratio
}

function main() {
    #输出cpu使用率统计信息
    local cpu_count=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
    results=($(Statistic_CPU_Ratio)) 
    echo $(WriteOutJson "cpu" ${results[0]})
    for ((i=1; i<=$cpu_count; i++))
    do
        c="cpu$[$i-1]"
        echo $(WriteOutJson "$c" ${results[$i]})
    done    

    #sleep 2m
    #输出内存使用统计信息
    memres=($(Statistic_MEM))
    echo $(WriteOutJson "mem_total" ${memres[0]})
    echo $(WriteOutJson "mem_used" ${memres[1]})
    echo $(WriteOutJson "app_used" ${memres[2]})
    echo $(WriteOutJson "mem_used_ratio" ${memres[3]})
    echo $(WriteOutJson "app_mem_used_ratio" ${memres[4]})
}

main
