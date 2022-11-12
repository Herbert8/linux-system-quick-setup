#!/bin/bash

# Install Docker Engine from binaries
# Document: https://docs.docker.com/engine/install/binaries/
# Download: https://download.docker.com/linux/static/stable/

# 定义基本颜色值
readonly TEXT_RESET_ALL_ATTRIBUTES=0
readonly TEXT_BOLD_BRIGHT=1
readonly TEXT_UNDERLINED=4
readonly COLOR_F_RED=31
readonly COLOR_F_LIGHT_RED=91

# 定义输出颜色
readonly STYLE_TITLE="\033[${TEXT_RESET_ALL_ATTRIBUTES}m\033[${TEXT_BOLD_BRIGHT}m\033[${TEXT_UNDERLINED}m"
readonly STYLE_NORMAL="\033[${TEXT_RESET_ALL_ATTRIBUTES}m"
readonly STYLE_TITLE_IMPORTANT="\033[${TEXT_RESET_ALL_ATTRIBUTES}m\033[${TEXT_BOLD_BRIGHT}m\033[${COLOR_F_RED}m"
readonly STYLE_NORMAL_IMPORTANT="\033[${TEXT_RESET_ALL_ATTRIBUTES}m\033[${COLOR_F_LIGHT_RED}m"

# 获取 shell 脚本绝对路径
base_dir () { dirname "${BASH_SOURCE[0]}"; }
BASE_DIR=$(base_dir)
readonly BASE_DIR

install_docker_binary () {

    # 常量定义 ======================================================================
    # 这里可以根据需要来指定相应的常量值
    # 要安装的 docker 二进制包文件
    readonly DOCKER_PACKAGE="$1"
    # 安装到的位置
    readonly DOCKER_STORAGE_PATH="/opt"
    # *-*-*-*-*-*- 新的 Docker 数据存储位置，这里提供默认值，使用时根据需要修改 *-*-*-*-*-*-*
    readonly NEW_DOCKER_DATA_STORAGE_PATH="$2"
    # systemd 服务名
    readonly UNIT_NAME="docker_static.service"
    # systemd Unit 文件位置
    readonly UNIT_FILE="/usr/lib/systemd/system/$UNIT_NAME"
    # ==============================================================================


    # 判断指定文件是否存在
    if [[ ! -f "$DOCKER_PACKAGE" ]]; then
        echo "File '$DOCKER_PACKAGE' does not exist."
        exit 1
    fi

    # 判断指定的存储位置是否存在
    if [[ ! -d "$NEW_DOCKER_DATA_STORAGE_PATH" ]]; then
        echo "New docker storage PATH '$NEW_DOCKER_DATA_STORAGE_PATH' does not exist."
        exit 1
    fi

    # 为新的 Docker 数据存储位置 在 原来对应的默认位置创建 Symbolic Link
    echo -e "${STYLE_TITLE}Map new docker storage by symbolic links:${STYLE_NORMAL}"
    echo "$NEW_DOCKER_DATA_STORAGE_PATH/ -> /var/lib/docker/"
    sudo mkdir -p "$NEW_DOCKER_DATA_STORAGE_PATH"
    sudo ln -sf "$NEW_DOCKER_DATA_STORAGE_PATH" '/var/lib/docker'

    # 解压缩
    sudo echo
    echo -e "${STYLE_TITLE}Extract files:${STYLE_NORMAL}"
    sudo tar zxvf "$DOCKER_PACKAGE" -C "$DOCKER_STORAGE_PATH"

    # 创建 Symbolic Link
    echo
    echo -e "${STYLE_TITLE}Create symbolic links:${STYLE_NORMAL}"
    for file in "${DOCKER_STORAGE_PATH}/docker/"*; do
        sudo ln -sf "$file" "/usr/bin/$(basename $file)";
        echo "/usr/bin/$(basename $file) -> $file";
    done

    # 创建服务
    echo
    echo -e "${STYLE_TITLE}Docker Daemon Unit:${STYLE_NORMAL}"
    sudo systemctl stop "$UNIT_NAME"
    sudo systemctl disable "$UNIT_NAME"
    cat << EOF | sudo tee "$UNIT_FILE"
# /usr/lib/systemd/system/docker_static.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com/engine/install/binaries/
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/dockerd
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    # 启动服务
    echo
    echo -e "${STYLE_TITLE}Start service:${STYLE_NORMAL}"
    sudo systemctl enable "$UNIT_NAME"
    sudo systemctl start "$UNIT_NAME"

    # 将当前用户添加到 docker 组，并重启服务
    echo
    echo -e "${STYLE_TITLE}Add user \"${USER}\" to the \"docker\" group:${STYLE_NORMAL}"
    sudo groupadd docker
    sudo gpasswd -a "${USER}" docker
    sudo systemctl restart "$UNIT_NAME"

    # 显示服务状态
    echo
    echo -e "${STYLE_TITLE}Show docker service status:${STYLE_NORMAL}"
    sudo systemctl status "$UNIT_NAME"

    # 提示用户注销后重新登录
    echo
    echo -e "${STYLE_TITLE_IMPORTANT}============== Important ==============${STYLE_NORMAL}"
    echo -e "${STYLE_NORMAL_IMPORTANT}User \"${USER}\" must logout and login again to operate docker!!!${STYLE_NORMAL}"
    echo
}


# 安装 Docker
new_docker_data_storage_path='/srv/docker_data'
# 使用 user_input_docker_storage_path 存放返回值
user_input_docker_storage_path=$(dialog --title "Choose a new storage path for Docker" \
                                    --backtitle 'System Setup' \
                                    --stdout \
                                    --dselect "$new_docker_data_storage_path" 12 60)
sel_path_ret="$?"
new_docker_data_storage_path="$user_input_docker_storage_path"
echo
# 处理用户输入
if [[ "0" -eq "$sel_path_ret" ]]; then
    # 如果用户确认，创建目录
    sudo mkdir -p "$new_docker_data_storage_path"
    # 安装 Docker
    install_docker_binary \
        "$BASE_DIR/docker-20.10.21.tgz" \
        "$new_docker_data_storage_path"
else
    echo -e "${STYLE_NORMAL_IMPORTANT}User cancels operation, skipping Docker installation.${STYLE_NORMAL}"
    echo
fi


