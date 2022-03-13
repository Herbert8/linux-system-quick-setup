#!/bin/bash

# 获取 shell 脚本绝对路径
base_dir () { (cd "$(dirname "${BASH_SOURCE[0]}")"; pwd;) }
readonly BASE_DIR=$(base_dir)


# 安装到 /opt/tools
echo
echo -e "\033[1mCopy the portable tools:\033[0m"
readonly TOOLS_DIR_NAME='portable_tools'
sudo mkdir -p /opt/$TOOLS_DIR_NAME
sudo cp -v "$BASE_DIR/$TOOLS_DIR_NAME"/* "/opt/$TOOLS_DIR_NAME/"
sudo chmod +x "/opt/$TOOLS_DIR_NAME"/*

# 在 /usr/local/bin/ 创建 Symbolic Link
echo
echo -e "\033[1mCreate symlinks for portable tools:\033[0m"
for file in /opt/$TOOLS_DIR_NAME/*; do
    sudo ln -sf "$file" /usr/local/bin/$(basename "$file")
    echo -e "/usr/local/bin/$(basename "$file") -> $file"
done

