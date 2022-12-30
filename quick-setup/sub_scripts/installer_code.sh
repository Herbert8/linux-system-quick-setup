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
    TEMP_ROOT_DIR=~/.local/mocha
fi
readonly TEMP_ROOT_DIR
readonly TEMP_DIR=$TEMP_ROOT_DIR/.cache/mp_inst

mkdir -p "$TEMP_DIR"


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
    >&2 echo "Extracting '$2' block data to '$3' ..."
    mkdir -p "$3"
    extract_block_from_bash_script "$2" "$1" \
                     | tar -zxvf - -C "$3" 2>&1 \
                     | print_scroll_in_range 3
}


if [[ "Linux" != "$(uname)" ]]; then
    echo OS must be Linux.
    exit 1
fi

# 安装对话框
install_dialog


# 安装基础配置 *******************************************************************
menu_item_index=$(( ${#ITEM_TAG_ARRAY[@]} + 1 ))
ITEM_TAG_ARRAY["$menu_item_index"]=$menu_item_index
ITEM_DESC_ARRAY["$menu_item_index"]='Install "User Configuration"'
ITEM_CMD_ARRAY["$menu_item_index"]='install_config'
ITEM_STATUS_ARRAY["$menu_item_index"]='on'

# 安装工具 *******************************************************************
menu_item_index=$(( ${#ITEM_TAG_ARRAY[@]} + 1 ))
ITEM_TAG_ARRAY["$menu_item_index"]=$menu_item_index
ITEM_DESC_ARRAY["$menu_item_index"]='Install Tools'
ITEM_CMD_ARRAY["$menu_item_index"]='install_all_tools'
ITEM_STATUS_ARRAY["$menu_item_index"]='on'


# 安装通用工具包 *******************************************************************
# menu_item_index=$(( ${#ITEM_TAG_ARRAY[@]} + 1))
# ITEM_TAG_ARRAY[$menu_item_index]=$menu_item_index
# ITEM_DESC_ARRAY[$menu_item_index]='Install Common Software Packages (rpm format, "root privilege" needed)'
# ITEM_CMD_ARRAY[$menu_item_index]='install_rpm_package'
# ITEM_STATUS_ARRAY[$menu_item_index]='off'


# 安装 Docker *******************************************************************
# menu_item_index=$(( ${#ITEM_TAG_ARRAY[@]} + 1))
# ITEM_TAG_ARRAY[$menu_item_index]=$menu_item_index
# ITEM_DESC_ARRAY[$menu_item_index]='Install Docker Static Binary ("root privilege" needed)'
# ITEM_CMD_ARRAY[$menu_item_index]='install_docker_binary'
# ITEM_STATUS_ARRAY[$menu_item_index]='off'


# functions

install_config () {
    local data_dir
    data_dir="$TEMP_DIR/config"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$SCRIPT_FILE" Config "$data_dir"
    # 如果使用了 sudo，则将 Owner 指定为 sudoer
    set_tmp_file_permission "$data_dir"
    # 脚本安装位置
    local scripts_root=$SOFT_ROOT/etc
    mkdir -p "$scripts_root" && bash "$data_dir/install_config.sh" "$scripts_root"
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

install_rpm_package_rotless () {
    local data_dir
    data_dir="$TEMP_DIR/rpm"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$SCRIPT_FILE" RPM "$data_dir"
    # 工具安装位置
    local tool_root=$SOFT_ROOT
    mkdir -p "$tool_root" && bash "$data_dir/install_rpm_package_rootless.sh" "$tool_root"
}

install_standalone_tools () {
    local data_dir
    data_dir="$TEMP_DIR/tools"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$SCRIPT_FILE" 'Standalone Tools' "$data_dir"
    # 如果使用了 sudo，则将 Owner 指定为 sudoer
    set_tmp_file_permission "$TEMP_ROOT_DIR"
    # 工具安装位置
    local tool_root=$SOFT_ROOT/usr/bin
    mkdir -p "$tool_root" && bash "$data_dir/install_standalone_tools.sh" "$tool_root"
}

install_portable_tools () {
    local data_dir
    data_dir="$TEMP_DIR/tools"
    mkdir -p "$data_dir"
    untar_files_from_block_to_directory "$SCRIPT_FILE" 'Portable Tools' "$data_dir"
    # 如果使用了 sudo，则将 Owner 指定为 sudoer
    set_tmp_file_permission "$TEMP_ROOT_DIR"
    # 工具安装位置
    local tool_root=$SOFT_ROOT/opt
    mkdir -p "$tool_root" && bash "$data_dir/install_portable_tools.sh" "$tool_root"
}

install_all_tools () {
    install_portable_tools
    install_standalone_tools
    install_rpm_package_rotless
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


# 选择要安装的内容，用户取消输入则退出
item_count=${#ITEM_TAG_ARRAY[@]}
menu_height=$(( item_count + 8 ))
if ! user_input=$(echo "$item_list" | \
                LD_LIBRARY_PATH="$TEMP_DIR" xargs "$TEMP_DIR/dialog" \
                --stdout --title "System Configuration Menu" \
                --backtitle "System Initialization" \
                --checklist "Select the function item you need:" $menu_height 90 $item_count); then
    clear
    echo "User cancels the operation."
    exit 1
fi

# 解析用户输入
read -ra user_input_array <<< "$user_input"

# 软件安装的根位置
# SOFT_ROOT=~/mocha/opt
SOFT_ROOT=~/.local/mocha
if ! SOFT_ROOT=$(LD_LIBRARY_PATH="$TEMP_DIR" "$TEMP_DIR/dialog" --stdout \
                    --title "Select the installation directory" \
                    --backtitle "System Initialization" \
                    --dselect "$SOFT_ROOT" 13 90); then
    clear
    echo "User cancels the operation."
    exit 1
fi
# 处理路径中存在多个 / 的情况
SOFT_ROOT=$(dirname "$SOFT_ROOT/placeholder")
mkdir -p "$SOFT_ROOT"

clear
# 处理用户选择的安装项
for user_selected_item in "${user_input_array[@]}"; do
    ${ITEM_CMD_ARRAY[$user_selected_item]}
done

echo
echo Done.
echo