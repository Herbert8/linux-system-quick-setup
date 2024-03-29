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
    PROJECT_ROOT=$BASE_DIR/..
    readonly PROJECT_ROOT

    # 工具包文件名
    tool_package_name=tools-pkg.tar.gz

    # 创建临时目录
    TMP_DIR=$(mktemp -d)
    # echo "$TMP_DIR"

    # 工具目录
    TOOL_DIR=$TMP_DIR/tool

    mkdir -p "$TOOL_DIR"
}

extract_package () {
    local pkg_full_name
    pkg_full_name=${1:-}
    if [[ -f "$pkg_full_name" ]]; then
        local pkg_name
        pkg_name=$(basename "$pkg_full_name" '.tar.gz')
        local pkg_path
        pkg_path=$TOOL_DIR/$pkg_name
        mkdir -p "$pkg_path" && tar zxf "$pkg_full_name" -C "$pkg_path"
    fi
}

# 获取目录中的文件数量，不包含隐藏文件。访问失败或目录不存在，则认为没有文件
file_count_in_dir () {
    ls "$1" 2>/dev/null | wc -l
}

dir_contain_file () {
    local file_count
    file_count=$(file_count_in_dir "$1")
    [[ '0' -lt "$file_count" ]]
}

# 处理一个 rpm 包
# $1 要处理的 rpm 包
# $2 工作目录
process_one_rpm () {
    local a_rpm=$1
    local work_path=$2
    (
        cd "$work_path" \
            && echo "Processing '$(basename "$a_rpm")' ..." \
            && rpm2cpio "$a_rpm" | cpio -div 2>&1 | print_scroll_in_range 3 \
            && echo -e "Process '$(basename "$a_rpm")' complete.\n"
    )
}

# 处理指定目录中的 *.rpm 包
# 第一个参数指定 rpm 包所在目录
process_rpms () {

    cp_files () {
        local src_dir=$1
        local dest_dir=$2
        mkdir -p "$dest_dir"
        if dir_contain_file "$src_dir"; then
            cp -vR "$src_dir"/* "$dest_dir" | print_scroll_in_range 3
        fi
    }

    local rpm_list=(
        bc
        dialog
        hstr
        htop
        iperf
        jq
        lsof
        multitail
        net-tools
        nmap
        openssl
        pigz
        socat
        tcpdump
        telnet
        the_silver_searcher
        traceroute
        tree
        unzip
        zip
        zstd
    )
    readonly rpm_list

    local rpm_dir=${1:-'.'}
    local work_dir=$TMP_DIR/work
    local epel_tool_dir=$TOOL_DIR/epel
    mkdir -p "$epel_tool_dir"
    # 遍历 rpm 包，解压缩到临时目录
    # 遍历方式：先遍历文件夹，再遍历文件夹中的 rpm 包。目的是把相同文件夹中的rpm包作为一组工具处理
    # 如果没有提供依赖库，则放到 standalone 工具目录中
    # find "$rpm_dir" -type d -name '*' | while read -r dir_item; do
    for rpm_name in "${rpm_list[@]}"; do
        local dir_item=$rpm_dir/$rpm_name
        mkdir -p "$work_dir/usr/bin"
        mkdir -p "$work_dir/usr/sbin"
        find "$dir_item" -maxdepth 1 -type f -name '*.rpm' | while read -r rpm_item; do
            process_one_rpm "$rpm_item" "$work_dir"
        done
        # 判断库目录是否存在或者目录中是否存在文件，决定作为独立工具处理，还是 epel 工具处理
        local rpm_tool_dir
        if dir_contain_file "$work_dir/usr/lib64"; then
            rpm_tool_dir=$epel_tool_dir
        else
            rpm_tool_dir=$TOOL_DIR
        fi
        # echo 'Copy binary files from "/usr/bin" "/usr/sbin" "/usr/lib64" ...'
        # {
            cp_files "$work_dir/usr/bin"      "$rpm_tool_dir"
            cp_files "$work_dir/usr/sbin"     "$rpm_tool_dir"
            cp_files "$work_dir/usr/lib64"    "$rpm_tool_dir/lib64"
            cp_files "$work_dir/usr/libexec"  "$rpm_tool_dir/libexec"
            cp_files "$work_dir/bin"          "$rpm_tool_dir"
            cp_files "$work_dir/sbin"         "$rpm_tool_dir"
        # } && echo -e 'Copy binary files completed.\n'
        rm -rf "$work_dir"
    done

    # 清理工作目录
    rm -rf "$work_dir"
}

process_portable_tool () {
    local portable_dir=$TMP_DIR/portable_tools
    mkdir -p "$portable_dir"
    cp "$PROJECT_ROOT/extractor/vim_static/out"/vim_full*.tar.gz "$portable_dir"/vim.tar.gz
    cp "$PROJECT_ROOT/extractor/tmux/out"/tmux*.tar.gz "$portable_dir"/tmux.tar.gz
    find "$portable_dir" -type f -name '*.tar.gz' | while read -r tool_pkg; do
        extract_package "$tool_pkg"
    done
    rm -rf "$portable_dir"
}

package_files () {
    (
        echo 'Start packing files using tar ...'
        cd "$TMP_DIR" \
            && gtar --exclude=.DS_Store -zcf "$tool_package_name" -- * | print_scroll_in_range 8 \
            && echo 'Packing files are completed.'
    )
}

gen_version_info () {
    # git rev-parse --short HEAD
    local commit_id
    commit_id=$(git rev-parse HEAD)

    local ref_str
    ref_str=$(git show -s --format=%d)

    # 文件变化数量
    local changed_file_count
    changed_file_count=$(git diff --name-only HEAD 2> /dev/null | wc -l | xargs)

    # 文件变化数量字符串
    local changed_file_count_str=''
    if [[ "$changed_file_count" -ne "0" ]]; then
        changed_file_count_str="{$changed_file_count}"
    fi

    # 提交时间
    local commit_time
    # 格式参见 https://blog.csdn.net/liurizhou/article/details/89234032
    commit_time=$(git show -s --format=%ai)

    # 打包时间
    local package_time
    package_time=$(date "+%Y-%m-%d %H:%M:%S %z")

    cat << EOF
Commit ID    : $commit_id $changed_file_count_str
Ref          : $ref_str
Commit Date  : $commit_time
Package Date : $package_time
EOF

}

upload_to_server () {
    if ncat -w2 -zv 192.168.200.99 22; then
        local installer_package=$1
        local server_str='bahb@192.168.200.99'
        local server_path='/home/bahb/playground/commontools/'
        echo Uploading "'$installer_package'" to "'$server_str:$server_path'..."
        sshpass -p 1 ssh "$server_str" "mkdir -p '$server_path'; rm -rf '$server_path'/*; " \
            && sshpass -p 1 scp -r "$installer_package" "$server_str:$server_path" \
            && sshpass -p 1 ssh "$server_str" "cd '$server_path' && tar zxf *.tar.gz " | print_scroll_in_range 8 \
            && echo upload complete.
    fi
}

select_standalone_tool () {
    (
        cd "$PROJECT_ROOT/components/standalone_tools/standalone_tools" && \
            cp -v bandwhich \
                7zz \
                bat \
                broot \
                btop \
                coreutils \
                curl8 \
                curlie \
                delta \
                duf \
                dust \
                exa \
                fd \
                fx \
                fzf \
                gitui \
                hexyl \
                httpbingo \
                lf \
                mcfly \
                ncdu \
                procs \
                rg \
                websocat \
                yq \
                zoxide \
                "$TOOL_DIR"/
    )
}

main () {

    # 准备目录
    prepare_dir

    echo "Working in '$TMP_DIR'."
    echo

    # 先处理可以独立运行的工具
    select_standalone_tool | print_scroll_in_range 8

    # 复制脚本
    cp -vR "$PROJECT_ROOT/components/accessory"/* "$TMP_DIR" | print_scroll_in_range 8

    # 处理 rpm 文件
    process_rpms "$PROJECT_ROOT/components/rpm/packages"

    # 如果带有 vim 参数，则重新构建 vim
    if [[ "vim" == "${1:-}" ]]; then
        bash "$PROJECT_ROOT/extractor/vim_static/extract.sh" | print_scroll_in_range 15
    fi
    # 处理便携工具
    process_portable_tool | print_scroll_in_range 8

    # 增加可执行权限
    chmod +x "$TOOL_DIR"/*

    # 复制用于配置的脚本
    cp "$PROJECT_ROOT/configurator/configure.sh" "$TMP_DIR/"

    # 版本信息
    gen_version_info > "$TMP_DIR/VERSION"

    # 打包
    package_files

    # 复制打包后的文件
    cp "$TMP_DIR/$tool_package_name" "$PROJECT_ROOT/dist/"

    echo
    # 上传服务器
    upload_to_server "$PROJECT_ROOT/dist/$tool_package_name"

    # 清理临时文件
    rm -rf "$TMP_DIR"

}

main "$@"

# echo '=========================================================================='

# echo "$TMP_DIR"
# open "$TMP_DIR"
