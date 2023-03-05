#!/bin/bash

set -eu

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

# 准备并创建目录
prepare_dir () {
    # 获取当前脚本所在位置
    BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    readonly BASE_DIR

    # 创建临时目录
    tmp_dir=$(mktemp -d)
    # echo "$tmp_dir"

    # 工具目录
    tool_dir=$tmp_dir/tool
    # 脚本目录
    script_dir=$tmp_dir/script

    mkdir -p "$tool_dir"
    mkdir -p "$script_dir"
}

extract_package () {
    local pkg_full_name
    pkg_full_name=${1:-}
    if [[ -f "$pkg_full_name" ]]; then
        local pkg_name
        pkg_name=$(basename "$pkg_full_name" '.tar.gz')
        local pkg_path
        pkg_path=$tool_dir/$pkg_name
        mkdir -p "$pkg_path" && tar zxf "$pkg_full_name" -C "$pkg_path"
    fi
}

# 处理指定目录中的 *.rpm 包
# 第一个参数指定 rpm 包所在目录
process_rpms () {
    local rpm_dir=${1:-'.'}
    local work_dir=$tmp_dir/work
    mkdir -p "$work_dir/usr/bin"
    mkdir -p "$work_dir/usr/sbin"
    # 遍历 rpm 包，解压缩到临时目录
    find "$rpm_dir" -type f -name '*.rpm' | while read -r item; do
        (
            cd "$work_dir" \
                && echo "Processing '$(basename "$item")' ..." \
                && rpm2cpio "$item" | cpio -div 2>&1 | print_scroll_in_range 3 \
                && echo -e "Process '$(basename "$item")' complete.\n"
        )
    done
    echo 'Copy binary files from "/usr/bin" "/usr/sbin" "/usr/lib64" ...'
    {
        cp -vR "$work_dir/usr/bin"/* "$tool_dir"/ | print_scroll_in_range 3
        cp -vR "$work_dir/usr/sbin"/* "$tool_dir"/ | print_scroll_in_range 3
        cp -vR "$work_dir/usr/lib64" "$tool_dir"/ | print_scroll_in_range 3
    } && echo -e 'Copy binary files completed.\n'


    # 清理工作目录
    rm -rf "$work_dir"
}

process_portable_tool () {
    local portable_dir=${1:-'.'}
    find "$portable_dir" -type f -name '*.tar.gz' | while read -r tool_pkg; do
        extract_package "$tool_pkg"
    done
}

package_files () {
    (
        echo 'Start packing files using tar ...'
        cd "$tmp_dir" &&
            gtar zcvf pkg.tar.gz -- * | print_scroll_in_range 8 &&
            echo 'Packing files are completed.'
    )
}

main () {

    # 准备目录
    prepare_dir

    echo "Working in '$tmp_dir'."
    echo

    # 先处理可以独立运行的工具
    cp -vR "$BASE_DIR/components/standalone_tools/standalone_tools"/* "$tool_dir"/ | print_scroll_in_range 8
    # 复制脚本
    cp -vR "$BASE_DIR/components/config/files/alias_function.sh" "$BASE_DIR/components/config/files/bash_prompt_style.sh" "$script_dir"/ | print_scroll_in_range 8

    # 处理 rpm 文件
    process_rpms "$BASE_DIR/components/rpm/packages"

    # 处理便携工具
    process_portable_tool "$BASE_DIR/components/portable_tools/portable_tools" | print_scroll_in_range 8

    # 增加可执行权限
    chmod +x "$tool_dir"/*

    # 复制用于配置的脚本
    cp "$BASE_DIR/config_tools.sh" "$tmp_dir/"

    # 打包
    package_files

    # 复制打包后的文件
    cp "$tmp_dir/pkg.tar.gz" "$BASE_DIR/dist/"

    # 清理临时文件
    rm -rf "$tmp_dir"

}

main

# echo '=========================================================================='

# echo "$tmp_dir"
# open "$tmp_dir"
