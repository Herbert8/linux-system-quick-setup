#!/bin/bash

# 获取 shell 脚本绝对路径
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly BASE_DIR

# 如果通过 sudo 以 root 权限执行，则将所有权指定为执行 sudo 的用户
change_owner_to_sudoer () {
    if [[ "$(id -u)" -eq "0" && -n "$SUDO_USER" && -n "$SUDO_UID" && -n "$SUDO_GID" ]]; then
        chown -vR "$SUDO_UID:$SUDO_GID" "$1"
    fi
}

SCRIPTS_DIR=${1:-'.'}
# 判断是否为 root 用户
# if [[ "$(id -u)" -eq "0" ]]; then
#     SCRIPTS_DIR=/opt/scripts
# else
#     SCRIPTS_DIR=~/mochasoft/opt/scripts
# fi
readonly SCRIPTS_DIR

# 创建脚本目录
mkdir -p "$SCRIPTS_DIR"

# 命令行提示符 *******************************************************************
readonly BASH_PROMPT_STYLE_FILE_NAME='bash_prompt_style.sh'

echo
echo -e "\033[1mNetwork devices list:\033[0m"
# 选择网络设备
device=$(/bin/bash "$BASE_DIR/select_network_menu.sh")
# 输出模板并替换网络设备，写入脚本文件
sed "s/#######_NETWORK_DEVICE_#######/$device/g" \
    "$BASE_DIR/files/$BASH_PROMPT_STYLE_FILE_NAME" \
    | tee "$SCRIPTS_DIR/$BASH_PROMPT_STYLE_FILE_NAME" > /dev/null

# 如果是 root 账号则创建软链接
if [[ "$(id -u)" -eq "0" ]]; then
    # 在 /etc/profile.d/ 创建 Symbolic Link
    ln -sf "$SCRIPTS_DIR/$BASH_PROMPT_STYLE_FILE_NAME" \
        "/etc/profile.d/$BASH_PROMPT_STYLE_FILE_NAME"
else
    echo "source $SCRIPTS_DIR/$BASH_PROMPT_STYLE_FILE_NAME" >> ~/.bashrc
fi

# vim 配置文件 ***************************************************************
# echo
# # 复制 vim 配置
# cp "$BASE_DIR/files/vimrc_custom" "$SCRIPTS_DIR"/
# if [[ "$(id -u)" -eq "0" ]]; then
#     # 如果是 root 用户，则 /etc/vimrc 作为配置文件
#     vim_config=/etc/vimrc
# else
#     vim_config=~/.vimrc
# fi

# # 将自定义配置注入默认配置文件
# echo -e "\033[1mThe following line will be added to '$vim_config':\033[0m"
# echo '----------------------------------------------------------------------'
# echo "source $SCRIPTS_DIR/vimrc_custom" | tee -a "$vim_config"
# echo '----------------------------------------------------------------------'
# echo
# # 如果通过 sudo 以 root 权限执行，则将所有权指定为执行 sudo 的用户
# change_owner_to_sudoer "$vim_config"
# chmod 644 "$vim_config"

# tmux 配置文件 **************************************************************
# if [[ "$(id -u)" -eq "0" ]]; then
#     tmux_config=/etc/tmux.conf
# else
#     tmux_config=~/.tmux.conf
# fi
# cp "$BASE_DIR/files/tmux.conf" "$SCRIPTS_DIR"/

# # 将自定义配置注入默认配置文件
# echo -e "\033[1mThe following line will be added to '$tmux_config':\033[0m"
# echo '----------------------------------------------------------------------'
# echo "source-file $SCRIPTS_DIR/tmux.conf" | tee -a "$tmux_config"
# echo '----------------------------------------------------------------------'
# echo
# # 如果通过 sudo 以 root 权限执行，则将所有权指定为执行 sudo 的用户
# change_owner_to_sudoer "$tmux_config"
# chmod 644 "$tmux_config"

# 别名和函数 ****************************************************************
readonly ALIAS_FUNC_FILE_NAME='alias_function.sh'
mkdir -p "$SCRIPTS_DIR"
cp "$BASE_DIR/files/$ALIAS_FUNC_FILE_NAME" "$SCRIPTS_DIR"/
# 如果通过 sudo 以 root 权限执行，则将所有权指定为执行 sudo 的用户
change_owner_to_sudoer "$SCRIPTS_DIR"

# 在 .bashrc 中引用 别名和函数文件
echo "source $SCRIPTS_DIR/$ALIAS_FUNC_FILE_NAME" >> ~/.bashrc
