#!/bin/bash

# 获取 shell 脚本绝对路径
this_script_full_filename () {
    # 脚本名称
    local bash_source_name=${BASH_SOURCE[0]}
    local script_file=$(readlink -f "${bash_source_name}")
    echo "$script_file"
}
readonly BASE_DIR=$(dirname $(this_script_full_filename))

# 安装到 /opt/tools
readonly TOOLS_DIR_NAME='portable_tools'
sudo mkdir -p /opt/$TOOLS_DIR_NAME
sudo cp $BASE_DIR/$TOOLS_DIR_NAME/* /opt/$TOOLS_DIR_NAME/
sudo chmod +x /opt/$TOOLS_DIR_NAME/*

# 在 /usr/local/bin/ 创建 Symbolic Link
for file in /opt/$TOOLS_DIR_NAME/*; do
    sudo ln -sf "$file" /usr/local/bin/$(basename "$file")
done

