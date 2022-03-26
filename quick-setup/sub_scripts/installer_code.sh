#!/bin/bash


# shopt -s expand_aliases

base_dir () { dirname "${BASH_SOURCE[0]}"; }
script_file () { echo "$(base_dir)/${BASH_SOURCE[0]}"; }


install_dialog () {
    # # 测试 dialog 是否存在
    # which dialog > /dev/null 2>&1

    # # 不存在则安装
    # if [[ "0" -ne "$?" ]]; then
    #     local dialog_rpm="$(mktemp).rpm"

    #     extract_block_from_bash_script 'Dialog' "$(script_file)" > "$dialog_rpm"
    #     sudo yum install -y "$dialog_rpm" > /dev/null || (rm "$dialog_rpm"; exit 1)
    #     rm "$dialog_rpm"
    # fi

    # local dialog_bin
    extract_block_from_bash_script 'Dialog' "$(script_file)" | tar zxf - -C "$(base_dir)" > /dev/null 2>&1
    chmod +x "$(base_dir)/dialog"
}

# 从 脚本文件中，提取 tar 包，并解压缩到目录
# $1 脚本文件
# $2 块名
# $3 解压缩到的文件夹
untar_files_from_block_to_directory () {
    mkdir -p "$3"
    extract_block_from_bash_script "$2" "$1" \
                     | tar -zxvf - -C "$3" 2>&1 \
                     | print_without_scroll_screen
}


if [[ "Linux" != "$(uname)" ]]; then
    echo OS must be Linux.
    exit 1
fi


# 申请 sudo 权限
sudo echo -ne || exit 1

# 安装对话框
install_dialog

# 解压缩安装包
# install_tmp_dir="$(base_dir)"
# mkdir -p "$install_tmp_dir"
# extract_block_from_bash_script 'System Setup Package' "$(script_file)" \
#                      | tar -zxvf - -C "$install_tmp_dir" \
#                      | print_without_scroll_screen

# clear_file "$install_tmp_dir/setup.sh"

# for file in "$install_tmp_dir"/**/*.sh; do
#     clear_file "$file"
# done

# bash "$install_tmp_dir/setup.sh"
# ============================================================================


# 安装基础配置 *******************************************************************
ITEM_TAG_ARRAY[1]=1
ITEM_DESC_ARRAY[1]='Install PS1 & vim config & tmux config'
ITEM_CMD_ARRAY[1]='install_config'
ITEM_STATUS_ARRAY[1]='on'



# 安装通用工具包 *******************************************************************
ITEM_TAG_ARRAY[2]=2
ITEM_DESC_ARRAY[2]="Install common 'rpm' packages"
ITEM_CMD_ARRAY[2]='install_common_package'
ITEM_STATUS_ARRAY[2]='on'

# 安装便携工具 *******************************************************************
ITEM_TAG_ARRAY[3]=3
ITEM_DESC_ARRAY[3]='Install portable tools'
ITEM_CMD_ARRAY[3]='install_portable_tools'
ITEM_STATUS_ARRAY[3]='on'

# 安装 Docker *******************************************************************
ITEM_TAG_ARRAY[4]=4
ITEM_DESC_ARRAY[4]='Install docker'
ITEM_CMD_ARRAY[4]='install_docker_binary'
ITEM_STATUS_ARRAY[4]='off'


# functions

install_config () {
    local data_dir
    data_dir="$(base_dir)/config"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$(script_file)" Config "$data_dir"
    bash "$data_dir/install_config.sh"
}

install_common_package () {
    local data_dir
    data_dir="$(base_dir)/common"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$(script_file)" Common "$data_dir"
    bash "$data_dir/install_common_package.sh"
}

install_portable_tools () {
    local data_dir
    data_dir="$(base_dir)/tools"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$(script_file)" 'Portable Tools' "$data_dir"
    bash "$data_dir/install_portable_tools.sh"
}

install_docker_binary () {
    local data_dir
    data_dir="$(base_dir)/docker"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$(script_file)" Docker "$data_dir"
    bash "$data_dir/install_docker_binary.sh" "$data_dir/docker-20.10.9.tgz"
}


# 遍历所有的命令项，生成菜单参数
for tag in "${ITEM_TAG_ARRAY[@]}"; do
    item_list="${item_list} ${tag} '${ITEM_DESC_ARRAY[${tag}]}' '${ITEM_STATUS_ARRAY[${tag}]}' "
done

user_input=$(echo "$item_list" | LD_LIBRARY_PATH="$(base_dir)" xargs "$(base_dir)/dialog" --stdout --title "System Configuration Menu" \
                --backtitle "System Initialization" \
                --checklist "Select the function item you need:" 13 60 6)

dialog_ret="$?"
# 用户取消输入则退出
if [[ "0" -ne "dialog_ret" ]]; then
    clear
    echo "User cancels the operation."
    exit 1
fi

# 解析用户输入
read -ra user_input_array <<< "$user_input"

clear
for user_selected_item in "${user_input_array[@]}"; do
    ${ITEM_CMD_ARRAY[$user_selected_item]}
done

