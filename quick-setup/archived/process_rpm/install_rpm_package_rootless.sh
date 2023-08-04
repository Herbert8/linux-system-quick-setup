#!/bin/bash


# 获取 shell 脚本绝对路径
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly BASE_DIR


# 安装到 /opt/tools
echo
echo -e "\033[1mProcess the rpm packages:\033[0m"

TOOLS_DIR=${1:-'.'}

readonly TOOLS_DIR

# 创建工具目录
mkdir -p "$TOOLS_DIR"

# 创建临时目录
tmp_dir=$(mktemp -d)
# echo "$tmp_dir"

# 清理前面输出的指定行数
clear_scroll_lines() {
    local lines_count=${1:-}
    [[ -z "$lines_count" ]] && return
    echo -ne "\033[${lines_count}A"
    for ((i = 0; i < lines_count; i++)); do
        echo -e "\033[K"
    done
    echo -ne "\033[${lines_count}A"
}

# 在指定范围内滚动
# 参考：https://zyxin.xyz/blog/2020-05/TerminalControlCharacters/
print_scroll_in_range() {
    # 默认最多显示滚动行数，默认为 8
    local scroll_lines=${1:-8}
    # 每行字符数，避免折行，默认 120
    local chars_per_line=${2:-120}
    local txt=''
    local last_line_count=0
    while read -r line; do
        line=${line:0:$chars_per_line}
        [[ "${last_line_count}" -gt "0" ]] && echo -ne "\033[${last_line_count}A"
        if [[ -z "$txt" ]]; then
            txt=$(echo -e "\033[2m$line\033[K" | tail -n"$scroll_lines")
        else
            txt=$(echo -e "$txt\n$line\033[K" | tail -n"$scroll_lines")
        fi
        last_line_count=$(($(wc -l <<<"$txt")))
        echo "$txt"
    done
    echo -ne "\033[0m"
    if [[ "$last_line_count" -gt "0" ]]; then
        clear_scroll_lines "$last_line_count"
    fi
}


# 相关 rpm +-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*

# 遍历 rpm 包，解压缩到临时目录
find "$BASE_DIR" -type f -name '*.rpm' | while read -r item; do
    (
        cd "$tmp_dir" \
            && echo "Processing '$(basename "$item")' ..." \
            && rpm2cpio "$item" | cpio -div 2>&1 | print_scroll_in_range 3 \
            && echo -e "Process '$(basename "$item")' complete.\n"
    )
done


mkdir -p "$TOOLS_DIR/usr/bin"
echo 'Copy extracted rpm contents ...'
if [[ -d "$tmp_dir/usr" ]]; then
    cp -vR "$tmp_dir/usr"/* "$TOOLS_DIR/usr" | print_scroll_in_range 3 && rm -rf "$tmp_dir"
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
