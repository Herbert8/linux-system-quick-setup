#!/bin/bash


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
