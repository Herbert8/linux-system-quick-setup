#!/bin/bash


# shopt -s expand_aliases

# 获取 shell 脚本绝对路径
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly BASE_DIR
SCRIPT_FILE=$BASE_DIR/$(basename "${BASH_SOURCE[0]}")
readonly SCRIPT_FILE


# 如果通过 sudo 以 root 权限执行，则将所有权指定为执行 sudo 的用户
set_tmp_file_permission () {
    if [[ "$(id -u)" -eq "0" && -n "$SUDO_USER" && -n "$SUDO_UID" && -n "$SUDO_GID" ]]; then
        chown -R "$SUDO_UID:$SUDO_GID" "$1"
        chmod -R 700 "$1"
    fi
}

# 根据身份处理临时文件权限
if [[ "$(id -u)" -eq "0" ]]; then
    # 如果是 root 身份，则临时文件在 /tmp 中
    TEMP_ROOT_DIR=/tmp/mocha
else
    TEMP_ROOT_DIR=~/mocha
fi
readonly TEMP_ROOT_DIR
readonly TEMP_DIR=$TEMP_ROOT_DIR/.tmp/mp_inst

mkdir -p "$TEMP_DIR"


# 软件安装的根位置
SOFT_ROOT=~/mocha
mkdir -p "$SOFT_ROOT"

install_dialog () {
    # local dialog_bin
    extract_block_from_bash_script 'Dialog' "$SCRIPT_FILE" | tar zx -C "$TEMP_DIR" > /dev/null 2>&1
    chmod +x "$TEMP_DIR/dialog"
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

# 安装对话框
install_dialog


# 安装基础配置 *******************************************************************
ITEM_TAG_ARRAY[1]=1
ITEM_DESC_ARRAY[1]='Install "PS1 config" & "vim config" & "tmux config"'
ITEM_CMD_ARRAY[1]='install_config'
ITEM_STATUS_ARRAY[1]='on'

# 安装便携工具 *******************************************************************
ITEM_TAG_ARRAY[2]=2
ITEM_DESC_ARRAY[2]='Install "Portable Tools"'
ITEM_CMD_ARRAY[2]='install_portable_tools'
ITEM_STATUS_ARRAY[2]='on'


# 安装通用工具包 *******************************************************************
ITEM_TAG_ARRAY[3]=3
ITEM_DESC_ARRAY[3]='Install Common Software Packages(rpm format, "root privilege" needed)'
ITEM_CMD_ARRAY[3]='install_rpm_package'
ITEM_STATUS_ARRAY[3]='off'


# 安装 Docker *******************************************************************
ITEM_TAG_ARRAY[4]=4
ITEM_DESC_ARRAY[4]='Install Docker("root privilege" needed)'
ITEM_CMD_ARRAY[4]='install_docker_binary'
ITEM_STATUS_ARRAY[4]='off'


# functions

install_config () {
    local data_dir
    data_dir="$TEMP_DIR/config"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$SCRIPT_FILE" Config "$data_dir"
    # 如果使用了 sudo，则将 Owner 指定为 sudoer
    set_tmp_file_permission "$data_dir"
    mkdir -p "$SOFT_ROOT/opt/scripts" && bash "$data_dir/install_config.sh" "$SOFT_ROOT/opt/scripts"
}

install_rpm_package () {
    local data_dir
    data_dir="$TEMP_DIR/rpm"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$SCRIPT_FILE" RPM "$data_dir"
    # 如果使用了 sudo，则将 Owner 指定为 sudoer
    set_tmp_file_permission "$TEMP_ROOT_DIR"
    bash "$data_dir/install_rpm_package.sh"
}

install_standalone_tools () {
    local data_dir
    data_dir="$TEMP_DIR/tools"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$SCRIPT_FILE" 'Standalone Tools' "$data_dir"
    # 如果使用了 sudo，则将 Owner 指定为 sudoer
    set_tmp_file_permission "$TEMP_ROOT_DIR"
    mkdir -p "$SOFT_ROOT/opt/tools" && bash "$data_dir/install_standalone_tools.sh" "$SOFT_ROOT/opt/tools"
}

install_portable_tools () {
    local data_dir
    data_dir="$TEMP_DIR/tools"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$SCRIPT_FILE" 'Portable Tools' "$data_dir"
    # 如果使用了 sudo，则将 Owner 指定为 sudoer
    set_tmp_file_permission "$TEMP_ROOT_DIR"
    mkdir -p "$SOFT_ROOT/opt/tools" && bash "$data_dir/install_portable_tools.sh" "$SOFT_ROOT/opt/tools"
    install_standalone_tools
}

install_docker_binary () {
    local data_dir
    data_dir="$TEMP_DIR/docker"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$SCRIPT_FILE" Docker "$data_dir"
    # 如果使用了 sudo，则将 Owner 指定为 sudoer
    set_tmp_file_permission "$TEMP_ROOT_DIR"
    bash "$data_dir/install_docker_binary.sh" "$data_dir/docker-20.10.9.tgz"
}


# 遍历所有的命令项，生成菜单参数
for tag in "${ITEM_TAG_ARRAY[@]}"; do
    item_list="${item_list} ${tag} '${ITEM_DESC_ARRAY[${tag}]}' '${ITEM_STATUS_ARRAY[${tag}]}' "
done

user_input=$(echo "$item_list" | LD_LIBRARY_PATH="$TEMP_DIR" xargs "$TEMP_DIR/dialog" --stdout --title "System Configuration Menu" \
                --backtitle "System Initialization" \
                --checklist "Select the function item you need:" 13 90 6)

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

echo
echo Done.
echo