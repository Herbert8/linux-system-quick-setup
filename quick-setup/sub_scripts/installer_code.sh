#!/bin/bash


# shopt -s expand_aliases

base_dir () { (cd "$(dirname "${BASH_SOURCE[0]}")"; pwd;) }
script_file () { echo "$(base_dir)/${BASH_SOURCE[0]}"; }


install_dialog () {
    # # 测试 dialog 是否存在
    # which dialog > /dev/null 2>&1

    # # 不存在则安装
    # if [[ "0" -ne "$?" ]]; then
    #     local dialog_rpm="$(mktemp).rpm"

    #     extract_block_from_bash_script 'Dialog' "$(script_file)" > "$dialog_rpm"
    #     sudo yum install -y "$dialog_rpm" > /dev/null || (rm "$dialog_rpm"; exit 1)
    #     rm "$dialog_rpm"
    # fi

    # local dialog_bin
    extract_block_from_bash_script 'Dialog' "$(script_file)" | tar zxf - -C "$(base_dir)"
    chmod +x "$(base_dir)/dialog"
}


# 申请 sudo 权限
sudo command || exit 1

# 安装对话框
install_dialog

# 解压缩安装包
install_tmp_dir="$(base_dir)"
mkdir -p "$install_tmp_dir"
extract_block_from_bash_script 'System Setup Package' "$(script_file)" \
                     | tar -zxvf - -C "$install_tmp_dir" \
                     | print_without_scroll_screen

clear_file "$install_tmp_dir/setup.sh"

for file in "$install_tmp_dir"/**/*.sh; do
    clear_file "$file"
done

bash "$install_tmp_dir/setup.sh"

