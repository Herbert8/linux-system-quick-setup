#!/bin/bash


# 获取 shell 脚本绝对路径
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly BASE_DIR


# 安装到 /opt/tools
echo
echo -e "\033[1mCopy the rpm tools:\033[0m"

TOOLS_DIR=${1:-'.'}

readonly TOOLS_DIR

# 创建工具目录
mkdir -p "$TOOLS_DIR"

# 创建临时目录
tmp_dir=$(mktemp -d)
# echo "$tmp_dir"

print_without_scroll_screen () {
    while read -r line; do echo -ne "\033[2K\r\033[2m$line"; done; echo -e "\033[0m"
}

# 相关 rpm +-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*

# 遍历 rpm 包，解压缩到临时目录
find "$BASE_DIR" -type f -name '*.rpm' | while read -r item; do
    (
        cd "$tmp_dir" && rpm2cpio "$item" | cpio -div 2>&1 | print_without_scroll_screen
    )
done


mkdir -p "$TOOLS_DIR/usr/bin"
if [[ -d "$tmp_dir/usr" ]]; then
    cp -vR "$tmp_dir/usr"/* "$TOOLS_DIR/usr" | print_without_scroll_screen && rm -rf "$tmp_dir"
fi

# 指定写入配置信息的文件，如果不具备写入权限则处理 ~/.bashrc
ALIAS_FUNCTION_FILE=$TOOLS_DIR/etc/alias_function.sh
[[ ! -w "$ALIAS_FUNCTION_FILE" ]] && ALIAS_FUNCTION_FILE=~/.bashrc

# 插入 PATH
SEARCH_PATH_TO_INSERT=$TOOLS_DIR/usr/sbin
SEARCH_PATH_TO_INSERT=${SEARCH_PATH_TO_INSERT/$HOME/'~'}
[[ -w "$ALIAS_FUNCTION_FILE" ]] && echo "export PATH=$SEARCH_PATH_TO_INSERT:\$PATH" >> "$ALIAS_FUNCTION_FILE"


# 插入 LD_LIBRARY_PATH
LIB_PATH=$TOOLS_DIR/usr/lib64
LIB_SEARCH_PATH_TO_INSERT=${LIB_PATH/$HOME/'~'}
[[ -w "$ALIAS_FUNCTION_FILE" ]] && echo "export LD_LIBRARY_PATH=$LIB_SEARCH_PATH_TO_INSERT:\$LD_LIBRARY_PATH" >> "$ALIAS_FUNCTION_FILE"
