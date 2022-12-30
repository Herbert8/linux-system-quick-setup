#!/bin/bash

# 获取 shell 脚本绝对路径
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly BASE_DIR

# 如果通过 sudo 以 root 权限执行，则将所有权指定为执行 sudo 的用户
change_owner_to_sudoer () {
    if [[ "$(id -u)" -eq "0" && -n "$SUDO_USER" && -n "$SUDO_UID" && -n "$SUDO_GID" ]]; then
        chown -R "$SUDO_UID:$SUDO_GID" "$1"
    fi
}

# 安装到 /opt/tools
echo
echo -e "\033[1mCopy the standalone tools:\033[0m"
# 指定目录名
readonly TOOLS_DIR_NAME='standalone_tools'

TOOLS_DIR=${1:-'.'}

# 根据用户指定完整目录路径
# if [[ "$(id -u)" -eq "0" ]]; then
#     TOOLS_DIR=/opt/$TOOLS_DIR_NAME
# else
#     TOOLS_DIR=~/mochasoft/opt/$TOOLS_DIR_NAME
#     echo "export PATH=$TOOLS_DIR:\$PATH" >> ~/.bashrc
# fi
readonly TOOLS_DIR

# 创建工具目录
mkdir -p "$TOOLS_DIR"
echo -ne "\033[2m"
# 复制工具文件
cp -vR "$BASE_DIR/$TOOLS_DIR_NAME"/* "$TOOLS_DIR/"
# 如果通过 sudo 以 root 权限执行，则将所有权指定为执行 sudo 的用户
change_owner_to_sudoer "$TOOLS_DIR"
# 根据当前用户权限，决定文件权限
if [[ "$(id -u)" -eq "0" ]]; then
    # 对于使用 root 权限安装的情况，认为做 全局工具安装，所以采用 755
    chmod -R 755 "$TOOLS_DIR"
else
    # 对于使用 非 root 权限安装时，只为当前用户设置使用权限
    chmod -R 700 "$TOOLS_DIR"
fi
echo -ne "\033[0m"

# broot 配置
BROOT_TOOL=$TOOLS_DIR/broot
if [[ -x "$BROOT_TOOL" ]]; then
    "$BROOT_TOOL" --install
fi

# 指定写入配置信息的文件，如果不具备写入权限则处理 ~/.bashrc
ALIAS_FUNCTION_FILE=$TOOLS_DIR/../../etc/alias_function.sh
[[ ! -w "$ALIAS_FUNCTION_FILE" ]] && ALIAS_FUNCTION_FILE=~/.bashrc


# 插入 PATH
SEARCH_PATH_TO_INSERT=${TOOLS_DIR/$HOME/'~'}
[[ -w "$ALIAS_FUNCTION_FILE" ]] && echo "export PATH=$SEARCH_PATH_TO_INSERT:\$PATH" >> "$ALIAS_FUNCTION_FILE"


# zoxide 配置
ZOXIDE_TOOL=$TOOLS_DIR/zoxide
# ZOXIDE_CONFIG=~/.bashrc_zoxide
if [[ -x "$ZOXIDE_TOOL" ]]; then
    # "$ZOXIDE_TOOL" init bash > "$ZOXIDE_CONFIG" && echo "source ~/.bashrc_zoxide" >> ~/.bashrc
    echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
fi

# 在 /usr/local/bin/ 创建 Symbolic Link
# 为减少对系统的影响，创建 Symbolic Link 的动作只在需要时选用
# echo
# echo -e "\033[1mCreate symlinks for portable tools:\033[0m"
# for file in /opt/"$TOOLS_DIR_NAME"/*; do
#     if [ -f "$file" ]; then
#         sudo ln -sf "$file" /usr/local/bin/"$(basename "$file")"
#         echo -e "/usr/local/bin/$(basename "$file") -> $file"
#     fi
# done

