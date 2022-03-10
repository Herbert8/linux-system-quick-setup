#!/bin/bash


# 获取 shell 脚本绝对路径
base_dir () { (cd "$(dirname "${BASH_SOURCE[0]}")"; pwd;) }

. "$(base_dir)/sub_scripts/file_utils.sh"


# echo $PATH

# readlink -f "$(which base64)"

# exit

tar_files () {
    tar --exclude=.DS_Store \
        --exclude=package.sh \
        --exclude=install.sh \
        -zcvf - *
}


install_script_template="$(base_dir)/sub_scripts/install_script.template"

cat "$install_script_template" \
        | sed '/^# /d' \
        | sed '/^alias/d' \
        | sed '/^debug/d' \
        | sed '/^$/d' \
        | cat - <( tar_files | data_to_base64_block 'System Setup Package' ) > install.sh


 # | sed '/^#/d' | sed '/^$/d'


# test_tar () {
#     echo abc123
# }

# cat "$install_script_template" | cat - <( test_tar | data_to_base64_block 'System Setup Package' ) > install.sh

