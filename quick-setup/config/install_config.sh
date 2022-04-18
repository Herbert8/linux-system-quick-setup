#!/bin/bash


# 获取 shell 脚本绝对路径
base_dir () { dirname "${BASH_SOURCE[0]}"; }
BASE_DIR=$(base_dir)
readonly BASE_DIR
readonly SCRIPTS_DIR='/opt/scripts'

# 命令行提示符 *******************************************************************
readonly BASH_PROMPT_STYLE_FILE_NAME='bash_prompt_style.sh'
sudo mkdir -p "$SCRIPTS_DIR"

echo
echo -e "\033[1mNetwork devices list:\033[0m"
# 选择网络设备
device=$(/bin/bash "$BASE_DIR/select_network_menu.sh")
# 输出模板并替换网络设备，写入脚本文件
sed "s/#######_NETWORK_DEVICE_#######/$device/g" \
    "$BASE_DIR/files/$BASH_PROMPT_STYLE_FILE_NAME" \
    | sudo tee "$SCRIPTS_DIR/$BASH_PROMPT_STYLE_FILE_NAME" > /dev/null
# 在 /etc/profile.d/ 创建 Symbolic Link
sudo ln -sf "$SCRIPTS_DIR/$BASH_PROMPT_STYLE_FILE_NAME" \
    "/etc/profile.d/$BASH_PROMPT_STYLE_FILE_NAME"


# vim 全局配置文件 ***************************************************************
echo
sudo cp "$BASE_DIR/files/vimrc_custom" "$SCRIPTS_DIR"/
# 如果 /etc/vimrc 文件存在，则在其末尾引入自定义的配置文件
vim_global_config='/etc/vimrc'
if [[ -f "$vim_global_config" ]]; then
    echo -e "\033[1mThe following line will be added to '$vim_global_config':\033[0m"
    echo '----------------------------------------------------------------------'
    echo "source $SCRIPTS_DIR/vimrc_custom" | sudo tee -a "$vim_global_config"
    echo '----------------------------------------------------------------------'
    echo
fi

# tmux 全局配置文件 **************************************************************
sudo cp "$BASE_DIR/files/tmux.conf" "$SCRIPTS_DIR"/
tmux_global_config='/etc/tmux.conf'
echo -e "\033[1mThe following line will be added to '$tmux_global_config':\033[0m"
echo '----------------------------------------------------------------------'
echo "source-file $SCRIPTS_DIR/tmux.conf" | sudo tee -a "$tmux_global_config"
echo '----------------------------------------------------------------------'
echo

# 别名和函数
readonly ALIAS_FUNC_FILE_NAME='alias_function.sh'
sudo mkdir -p "$SCRIPTS_DIR"
sudo cp "$BASE_DIR/files/$ALIAS_FUNC_FILE_NAME" "$SCRIPTS_DIR"/
echo "source $SCRIPTS_DIR/$ALIAS_FUNC_FILE_NAME" >> ~/.bashrc
