
alias ll='exa -Fghl --time-style=long-iso --group-directories-first --color-scale'
alias lla='exa -aFghl --time-style=long-iso --group-directories-first --color-scale'

mount_rhel_disc () {
    local media_path='/media/rhel-cdrom'
    sudo mkdir -p "$media_path"
    sudo mount /dev/cdrom "$media_path"
    echo "mount: /dev/cdrom -> $media_path"
}

ssproxy () {
    local server_http_proxy='http://192.168.100.1:8888';
    local server_sock5h_proxy='socks5h://192.168.100.1:8889';
    export http_proxy=$server_http_proxy;
    export https_proxy=$server_http_proxy;
    export all_proxy=$server_sock5h_proxy;
    export no_proxy='192.168.*.*,127.0.0.1,localhost,0.0.0.0';
}

unproxy () {
    unset http_proxy;
    unset https_proxy;
    unset all_proxy;
}

whichex () {
    local full_path=$(which "$1")
    readlink -f "$full_path"
}

# 计算本地时间比标准时间（百度时间）“快”多少
fast_time () {
    # 访问百度获取头信息
    local exec_result_str
    exec_result_str=$(curl -H 'Cache-Control: no-cache' -sSI http://baidu.com 2>&1)
    # 执行结果，用于容错
    local exec_ret="$?"

    # 容错，执行失败时返回 err
    if [[ "0" -eq "$exec_ret" ]]; then
        # 百度时间字符串
        local baidu_time_str=$(echo "${exec_result_str}" | grep '^Date:' | cut -d' ' -f3-6)
        # 百度时间戳
        local baidu_time_stamp=$(date -ud "${baidu_time_str}" '+%s')
        # 本地时间戳
        local local_time_stamp=$(date '+%s')
        local fast_time=$[$local_time_stamp-$baidu_time_stamp]
        # 显示本地时间比标砖时间“快”多少
        echo "$fast_time"
    else
        >&2 echo "$exec_result_str"
        return "$exec_ret"
    fi
}

# 以百度时间为基准进行时间同步
sync_date () {
    sudo echo -ne && sudo date -s "$(curl -H 'Cache-Control: no-cache' -sI baidu.com | grep '^Date:' | cut -d' ' -f3-6)Z"
}

