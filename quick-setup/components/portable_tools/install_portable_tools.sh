#!/bin/bash

# 获取 shell 脚本绝对路径
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly BASE_DIR

PORTABLE_TOOL_DIR=${1:-'.'}

extract_package () {
    local pkg_full_name
    pkg_full_name=${1:-}
    if [[ -f "$pkg_full_name" ]]; then
        local pkg_name
        pkg_name=$(basename "$pkg_full_name" '.tar.gz')
        local pkg_path
        pkg_path=$PORTABLE_TOOL_DIR/$pkg_name
        mkdir -p "$pkg_path" && tar zxf "$pkg_full_name" -C "$pkg_path"
    fi
}

find "$BASE_DIR" -type f -name '*.tar.gz' | while read -r tool_pkg; do
    extract_package "$tool_pkg"
done


# 为 portable_tool 生成别名，注入 alias_function.sh
ALIAS_FUNCTION_FILE=$PORTABLE_TOOL_DIR/../etc/alias_function.sh
# alias_function.sh 不存在则注入 .bashrc
[[ ! -f "$ALIAS_FUNCTION_FILE" ]] && ALIAS_FUNCTION_FILE=~/.bashrc

alias_tool () {
    local tool_name=${1:-}
    local tool_path
    tool_path=$(find "$PORTABLE_TOOL_DIR" -maxdepth 2 ! -type d -name "$tool_name" | head -n1)
    tool_path=${tool_path/#$HOME\//'~/'}
    if [[ -n "$tool_path" ]]; then
        echo "alias ${tool_name}='$tool_path'" >> "$ALIAS_FUNCTION_FILE"
    fi
}

# [[ -x "$PORTABLE_TOOL_DIR/nmap/run" ]] && "$PORTABLE_TOOL_DIR/nmap/run"

alias_tool vim
alias_tool tmux
# alias_tool ncat
# alias_tool nmap
# alias_tool nping
# alias_tool jq


