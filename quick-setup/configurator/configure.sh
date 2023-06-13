
# 准备并创建目录
prepare_dir () {
    # 获取当前脚本所在位置
    BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
}

clear_dir () {
    unset BASE_DIR
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

main () {

    # 准备相关目录
    prepare_dir

    # 搜索路径
    export PATH=$BASE_DIR/tool:$BASE_DIR/tool/tmux:$BASE_DIR/tool/vim:$PATH
    export LD_LIBRARY_PATH=$BASE_DIR/tool/lib64:$LD_LIBRARY_PATH

    # 如果 不能 成功检测到使用的网络设备，则执行用户选择网络设备的逻辑
    if ! detect_network_device; then
        # 配置目录
        local config_dir=$BASE_DIR/.local/share/config
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


    # 加载配置脚本
    source "$BASE_DIR/script/alias_function.sh"
    source "$BASE_DIR/script/bash_prompt_style.sh" "$selected_network_device"


    # 设置别名
    alias vim="$BASE_DIR/tool/vim/vim"
    alias tmux="$BASE_DIR/tool/tmux/tmux"

    # 配置 zoxide
    eval "$("$BASE_DIR/tool/zoxide" init bash)"

    # 清理目录配置
    clear_dir
}

main
