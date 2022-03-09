#!/bin/bash


# 获取 shell 脚本绝对路径
base_dir () { (cd "$(dirname "${BASH_SOURCE[0]}")"; pwd;) }
readonly BASE_DIR=$(base_dir)

readonly SCRIPTS_DIR='/opt/scripts'
readonly PACKAGES_DIR='/opt/packages'

# 命令行提示符 *******************************************************************
readonly BASH_PROMPT_STYLE_FILE_NAME='bash_prompt_style.sh'
sudo mkdir -p "$SCRIPTS_DIR"

echo
echo -e "${STYLE_TITLE}Network devices list:${STYLE_NORMAL}"
# 选择网络设备
device=$(/bin/bash "$BASE_DIR/select_network_menu.sh")
# 输出模板并替换网络设备，写入脚本文件
cat "$BASE_DIR/files/$BASH_PROMPT_STYLE_FILE_NAME" \
    | sed "s/#######_NETWORK_DEVICE_#######/$device/g" \
    | sudo tee "$SCRIPTS_DIR/$BASH_PROMPT_STYLE_FILE_NAME" > /dev/null
# 在 /etc/profile.d/ 创建 Symbolic Link
sudo ln -sf "$SCRIPTS_DIR/$BASH_PROMPT_STYLE_FILE_NAME" \
    "/etc/profile.d/$BASH_PROMPT_STYLE_FILE_NAME"

# vim 全局配置文件 ***************************************************************
sudo cp "$BASE_DIR/files/vimrc_custom" /etc/
echo 'source /etc/vimrc_custom' | sudo tee -a /etc/vimrc

# tmux 全局配置文件 **************************************************************
sudo cp $BASE_DIR/files/tmux.conf /etc/

# 别名和函数
readonly ALIAS_FUNC_FILE_NAME='alias_function.sh'
sudo mkdir -p "$SCRIPTS_DIR"
sudo cp "$BASE_DIR/files/$ALIAS_FUNC_FILE_NAME" "$SCRIPTS_DIR"/
echo "source $SCRIPTS_DIR/$ALIAS_FUNC_FILE_NAME" >> ~/.bashrc
