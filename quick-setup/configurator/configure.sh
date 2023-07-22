

is_bash () {
    test -n "$SHELL" && test -n "$BASH_SOURCE"
}

# 如果 使用的不是 Shell，则很可能是是功能比 Bash 要简单的 Shell，不予支持
if ! is_bash; then
    >&2 echo 'The shell provides too few functions, please configure them manually.'
    return 1
fi

# 准备并创建目录
prepare_dir () {
    # 获取当前脚本所在位置
    BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    SCRIPT_DIR=$BASE_DIR/script
    TOOL_DIR=$BASE_DIR/tool
    EPEL_TOOL_DIR=$TOOL_DIR/epel
}

clear_dir () {
    unset BASE_DIR
    unset TOOL_DIR
    unset EPEL_TOOL_DIR
}

select_network_device () {
    # 获取指定网卡 IP
    get_network_ip () {
        local ip_info
        ip_info=$(ip a s "$1" | sed -nr 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
        ip_info=${ip_info/$'\n'/ }
        echo "$ip_info"
    }

    # 通过菜单选择网络设备
    select_network_menu () {

        # 获取所有网络接口
        local network_devices
        network_devices=$(ip link | grep -E '^[0-9]' | awk -F ': ' '{print $2}')

        # 遍历网络接口，获取对应 IP
        local net_device_list
        net_device_list=$(for device in $network_devices; do
            local ip
            ip=$(get_network_ip "$device" 2>&1) || continue;
            if [[ "lo" == "$device" ]]; then
                continue
            fi
            echo -e "[$device]\t{$ip}"
        done)

        # 选择网络接口
        PS3='Select network device: '
        IFS=$'\n'
        net_device_list=$(echo "$net_device_list" | column -t -s$'\t')
        select item in $net_device_list; do
            # 指定的序号有内容则选定退出，没内容则继续选择
            if [[ -n "$item" ]]; then
                echo "$item"
                break
            fi
        done
    }

    selected_item=$(select_network_menu | awk '{ print $1 }')
    selected_item=${selected_item/[/}
    selected_item=${selected_item/]/}

    echo "$selected_item"
}

detect_network_device () {
    ip a s | grep 'inet .*noprefixroute' > /dev/null
}

write_ip_tag () {
    # 创建一个以 IP 地址为名称的文件，里面存入日期
    local str_ip
    str_ip=$(get_ip_addr)
    str_ip=${str_ip//\//-}
    str_ip=${str_ip//./_}
    get_date_time >> ~/".$str_ip"
}

# 获取动态链接库缓冲区
SYS_LD_CFG=$(ldconfig -p)

# 获取文件的依赖
get_file_dep () {
    local file=${1:-}
    objdump -x "$file" | grep NEEDED | sed -nr 's/.*NEEDED\s*(\S*)$/\1/p'
}

# 判断文件的依赖是否存在
get_file_dep_exist () {
    local file=${1:-}
    local deps
    deps=$(get_file_dep "$file")
    local dep_exist=1
    for a_dep in $deps; do
        if ! echo "$SYS_LD_CFG" | grep "$a_dep"$ > /dev/null; then
            dep_exist=0
            break
        fi
    done
    test "1" == "$dep_exist"
}



# 在目录中查找 依赖 存在 或 不存在 的文件
# $1 要搜索的目录
# $2 传入 1 指定显示依赖可用的文件，非 1 值 显示依赖不可用文件
find_dep_exist_files_in_path () {
    local find_in_path=${1:-.}
    local find_dep_exists_item=${2:-1}

    local dep_ok

    # 遍历文件
    find "$find_in_path" -type f | while read -r file_item; do
        # 判断是否为可执行文件，如果不是可执行文件则不做后续检查
        if [[ "$(file -b --mime-type "$file_item")" != 'application/x-executable' ]]; then
            continue
        fi
        # 判断文件依赖的内容是否存在
        if get_file_dep_exist "$file_item"; then
            dep_ok=1
        else
            dep_ok=0
        fi
        # 根据传入的 第二个参数，判断收集 具备依赖 或者 不具备依赖 的文件
        if [[ '1' == "$find_dep_exists_item" && '1' == "$dep_ok" ]] \
            || [[ '1' != "$find_dep_exists_item" && '1' != "$dep_ok" ]]; then
            readlink -f "$file_item"
        fi
    done
}

# 在 epel 工具中，查找依赖库完整的应用，创建 Symbolic Link
create_symbolic_link_for_epel () {
    local epel_tools
    epel_tools=$(find_dep_exist_files_in_path "$EPEL_TOOL_DIR" 1)
    local suffix
    for tool in $epel_tools; do
        suffix=${tool: -1}
        ln -sfr "$tool" "$TOOL_DIR/$(basename "$tool")$suffix"
    done
}

# 在 epel 工具中，查找依赖库 不完整的应用，创建 alias
create_alias_for_epel () {
    local epel_tools
    epel_tools=$(find_dep_exist_files_in_path "$EPEL_TOOL_DIR" 0)
    local suffix
    for tool in $epel_tools; do
        suffix=${tool: -1}
        alias "$(basename "$tool")$suffix"="LD_LIBRARY_PATH=$EPEL_TOOL_DIR/lib64 $tool"
    done
}

# 为所有的 epel 工具创建 alias
create_alias_for_all_epel () {
    local suffix
    # 遍历所有的 规则文件
    # find ... | while read ... 的方式不能用。因为这样会产生 子 Shell
    # 导致在其中执行的 alias 对 父 Shell 无效
    # find "$EPEL_TOOL_DIR" -type f | while read -r file_item; do
    # 使用先获取所有信息，再读取的方式，避免 子 Shell
    local all_files
    all_files=$(find "$EPEL_TOOL_DIR" -maxdepth 1 -type f)
    local ifs_bak=IFS

    IFS=$'\n'
    for file_item in $all_files; do
        # 处理具备 可执行权限 的文件
        if [[ -x "$file_item" ]]; then
            suffix=${file_item: -1}
            alias "$(basename "$file_item")$suffix"="LD_LIBRARY_PATH=$EPEL_TOOL_DIR/lib64 $file_item"
        fi
    done
    IFS=$ifs_bak
}

main () {

    # 准备相关目录
    prepare_dir

    # 搜索路径
    local new_path=$TOOL_DIR:$TOOL_DIR/tmux:$TOOL_DIR/vim
    export PATH=$new_path:$PATH

    # 如果 不能 成功检测到使用的网络设备，则执行用户选择网络设备的逻辑
    # 执行条件：Bash、ip、未检测到网络设备
    if is_bash && command -v ip > /dev/null && ! detect_network_device; then
        # 配置目录
        # local config_dir=$BASE_DIR/.local/share/config
        local config_dir=~/.local/share/config
        mkdir -p "$config_dir"

        # 选择网络设备
        local selected_network_device
        local selected_network_device_file=$config_dir/network-device.cfg
        # 如果有存储了选择设备的文件，则从指定文件中读取
        if [[ -r "$selected_network_device_file" ]]; then
            selected_network_device=$(cat "$selected_network_device_file")
        else
            # 否则用户选择
            selected_network_device=$(select_network_device)
            # 保存用户选择
            echo "$selected_network_device" > "$selected_network_device_file"
        fi
    fi


    # 如果使用 Bash 则 加载配置脚本
    if is_bash; then
        source "$BASE_DIR/script/alias_function.sh"
        source "$BASE_DIR/script/bash_prompt_style.sh" "$selected_network_device"
    fi


    # 如果是 Fedora/CentOS/RHEL
    # 原本想判断是否系统内有完整的依赖，有 则 创建 Symbolic Link
    # 没有则 创建 alias，运行时指定库搜索位置
    # 但是发现上面的方法初始化时间较长，对 I/O 性能依赖较高。尤其是在网络存储上，初始化过程缓慢
    # 所以先统一改为创建 alias 的方式
    # 这里通过 yum 来判断系统类型，有更好的方法可以替换
    # if command -v yum > /dev/null && command -v file > /dev/null; then
    #     create_symbolic_link_for_epel
    #     create_alias_for_epel
    # fi

    # 为所有 epel 的工具创建别名，通过别名运行时指定 LD_LIBRARY_PATH
    create_alias_for_all_epel

    # 为 curl8 指定别名，主要是指定证书
    # alias curl8="'$TOOL_DIR/curl8' --cacert '$SCRIPT_DIR/ca-certificates.crt'"
    # 通过环境变量指定证书文件
    # 参考：https://curl.se/docs/sslcerts.html
    alias curl8="CURL_CA_BUNDLE='$SCRIPT_DIR/ca-certificates.crt' '$TOOL_DIR/curl8'"

    # 由于便携版 tmux 使用了自己的 LD_LIBRARY_PATH
    # 为避免对其子进程的影响，如果是在 tmux 环境下
    # 取消 LD_LIBRARY_PATH
    if [[ -n "$TMUX"  ]]; then
        unset LD_LIBRARY_PATH
    fi

    # 配置 zoxide
    eval "$("$TOOL_DIR/zoxide" init bash)"

    # 配置 mcfly，ctrl+r 查看历史命令
    # eval "$("$TOOL_DIR/mcfly" init bash)"

    # 创建一个以 IP 地址为名称的文件，里面存入日期
    write_ip_tag

    # 清理目录配置
    clear_dir
}

main
