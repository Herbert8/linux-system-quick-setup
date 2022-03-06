#!/bin/bash

# 定义基本颜色值
readonly TEXT_RESET_ALL_ATTRIBUTES=0
readonly TEXT_BOLD_BRIGHT=1
readonly TEXT_UNDERLINED=4
readonly COLOR_F_RED=31
readonly COLOR_F_LIGHT_RED=91

# 定义输出颜色
readonly STYLE_TITLE="\033[${TEXT_RESET_ALL_ATTRIBUTES}m\033[${TEXT_BOLD_BRIGHT}m\033[${TEXT_UNDERLINED}m"
readonly STYLE_NORMAL="\033[${TEXT_RESET_ALL_ATTRIBUTES}m"
readonly STYLE_TITLE_IMPORTANT="\033[${TEXT_RESET_ALL_ATTRIBUTES}m\033[${TEXT_BOLD_BRIGHT}m\033[${COLOR_F_RED}m"
readonly STYLE_NORMAL_IMPORTANT="\033[${TEXT_RESET_ALL_ATTRIBUTES}m\033[${COLOR_F_LIGHT_RED}m"


# 获取 shell 脚本绝对路径
this_script_full_filename () {
    # 脚本名称
    local bash_source_name=${BASH_SOURCE[0]}
    local script_file=$(readlink -f "${bash_source_name}")
    echo "$script_file"
}
readonly BASE_DIR=$(dirname $(this_script_full_filename))


readonly SCRIPTS_DIR='/opt/scripts'
readonly PACKAGES_DIR='/opt/packages'

# 命令行提示符 *******************************************************************
readonly BASH_PROMPT_STYLE_FILE_NAME='bash_prompt_style.sh'
sudo mkdir -p "$SCRIPTS_DIR"

echo
echo -e "${STYLE_TITLE}Network devices list:${STYLE_NORMAL}"
# 选择网络设备
device=$(/bin/bash "$BASE_DIR/config/select_network_menu.sh")
# 输出模板并替换网络设备，写入脚本文件
cat "$BASE_DIR/config/$BASH_PROMPT_STYLE_FILE_NAME" \
    | sed "s/#######_NETWORK_DEVICE_#######/$device/g" \
    | sudo tee "$SCRIPTS_DIR/$BASH_PROMPT_STYLE_FILE_NAME" > /dev/null
# 在 /etc/profile.d/ 创建 Symbolic Link
sudo ln -sf "$SCRIPTS_DIR/$BASH_PROMPT_STYLE_FILE_NAME" \
    "/etc/profile.d/$BASH_PROMPT_STYLE_FILE_NAME"

# vim 全局配置文件 ***************************************************************
sudo cp "$BASE_DIR/config/vimrc_custom" /etc/
echo 'source /etc/vimrc_custom' | sudo tee -a /etc/vimrc

# tmux 全局配置文件 **************************************************************
sudo cp $BASE_DIR/config/tmux.conf /etc/

# 安装基础组件 *******************************************************************
sudo yum install -y $BASE_DIR/common/*.rpm $BASE_DIR/common/**/*.rpm

# 安装便携工具 *******************************************************************
/bin/bash "$BASE_DIR/tools/install_portable_tools.sh"

# 别名和函数
readonly ALIAS_FUNC_FILE_NAME='alias_function.sh'
sudo mkdir -p "$SCRIPTS_DIR"
sudo cp "$BASE_DIR/config/$ALIAS_FUNC_FILE_NAME" "$SCRIPTS_DIR"/
echo ". $SCRIPTS_DIR/$ALIAS_FUNC_FILE_NAME" >> ~/.bashrc

# 安装 Docker
new_docker_data_storage_path='/srv/docker_data'
# 使用 user_input_docker_storage_path 存放返回值
user_input_docker_storage_path=$(dialog --title "Choose a new storage path for Docker" \
                                    --backtitle 'System Setup' \
                                    --stdout \
                                    --dselect "$new_docker_data_storage_path" 12 60)
sel_path_ret="$?"
new_docker_data_storage_path="$user_input_docker_storage_path"
echo
# 处理用户输入
if [[ "0" -eq "$sel_path_ret" ]]; then
    # 如果用户确认，创建目录
    sudo mkdir -p "$new_docker_data_storage_path"
    # 安装 Docker
    /bin/bash $BASE_DIR/docker/install_docker_binary.sh \
        "$BASE_DIR/docker/docker-20.10.9.tgz" \
        "$new_docker_data_storage_path"
else
    echo -e "${STYLE_NORMAL_IMPORTANT}User cancels operation, skipping Docker installation.${STYLE_NORMAL}"
    echo
fi

