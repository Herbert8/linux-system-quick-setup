

alias ll='ls -lp --time-style=long-iso --group-directories-first --color=auto'
alias llh='ll -h'
alias lla='ll -a'

alias treex='tree --dirsfirst -CF'
alias treexansi='tree --charset ansi --dirsfirst -CF'

command -v exa > /dev/null && {
    alias lle='exa -Fghl --time-style=long-iso --group-directories-first --color-scale'
    alias llea='exa -aFghl --time-style=long-iso --group-directories-first --color-scale'
}



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
    readlink -f "$(which "$1")"
}

llex () {
    ls -alp --time-style=long-iso --group-directories-first --color=auto "$(readlink -f "$(which "$1")")"
}

# 进入文件所在目录
cdf () {
    local filename=${1:-}
    local pathname
    pathname=$(dirname "$filename")
    cd "$pathname"
}

# 进入文件真实位置所在目录
cdrf () {
    local filename=${1:-}
    if real_filename=$(readlink -f "$filename"); then
        # readlink -f 只有在目录存在时才返回成功，这时执行 cd
        cdf "$real_filename"
    else
        # 否则报错
        cd "$(dirname "$filename")"
    fi
}

# 计算本地时间比指定 Web 服务器“快”多少
time_diff () {
    # 指定获取标准时间的 Web 服务器
    local web_server
    # 如果不指定则使用百度服务器作为基准时间
    web_server=${1:-'http://baidu.com'}
    # 访问 Web 服务器获取头信息
    local exec_result_str
    exec_result_str=$(curl -H 'Cache-Control: no-cache' -sSI "$web_server" 2>&1)
    # 保存执行结果，用于容错
    local exec_ret="$?"

    # 判断执行结果
    if [[ "0" -eq "$exec_ret" ]]; then
        # Web 服务器时间字符串
        local server_time_str
        server_time_str=$(echo "${exec_result_str}" | grep '^Date:' | cut -d' ' -f3-6)
        # Web 服务器时间戳
        local server_time_stamp
        server_time_stamp=$(date -ud "${server_time_str}" '+%s')
        # 本地时间戳
        local local_time_stamp
        local_time_stamp=$(date '+%s')
        local time_diff=$(( local_time_stamp - server_time_stamp))
        # 显示本地时间比标砖时间“快”多少
        echo "$time_diff"
    else
        >&2 echo "$exec_result_str"
        return "$exec_ret"
    fi
}


# 通过指定 Web 服务器来校正时间
# https://www.jianshu.com/p/231880efaef7
sync_time () {
    # 指定获取标准时间的 Web 服务器
    local web_server
    # 如果不指定则使用百度服务器作为基准时间
    web_server=${1:-'http://baidu.com'}
    # 申请 sudo 权限，失败则返回
    sudo echo -n || return
    # 获取 response 头，失败则返回
    local header
    header=$(curl -H 'Cache-Control: no-cache' -sSI "$web_server") || return
    # 提取时间
    local date_str
    date_str=$(echo "$header" | grep '^Date:' | cut -d' ' -f3-6)
    # 设置时间
    sudo date -s "${date_str}Z"
}
