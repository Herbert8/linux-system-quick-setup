#!/bin/bash


# 获取 shell 脚本绝对路径
base_dir () { (cd "$(dirname "${BASH_SOURCE[0]}")"; pwd;) }
readonly BASE_DIR=$(base_dir)

# exit

# 安装基础配置 *******************************************************************
ITEM_TAG_ARRAY[1]=1
ITEM_DESC_ARRAY[1]='Install PS1 & vim config & tmux config'
ITEM_CMD_ARRAY[1]='install_config'
ITEM_STATUS_ARRAY[1]='on'



# 安装通用工具包 *******************************************************************
ITEM_TAG_ARRAY[2]=2
ITEM_DESC_ARRAY[2]="Install common 'rpm' packages"
ITEM_CMD_ARRAY[2]='install_common_package'
ITEM_STATUS_ARRAY[2]='on'

# 安装便携工具 *******************************************************************
ITEM_TAG_ARRAY[3]=3
ITEM_DESC_ARRAY[3]='Install portable tools'
ITEM_CMD_ARRAY[3]='install_portable_tools'
ITEM_STATUS_ARRAY[3]='on'

# 安装 Docker *******************************************************************
ITEM_TAG_ARRAY[4]=4
ITEM_DESC_ARRAY[4]='Install docker'
ITEM_CMD_ARRAY[4]='install_docker_binary'
ITEM_STATUS_ARRAY[4]='off'


# functions

install_config () {
    /bin/bash "$BASE_DIR/config/install_config.sh"
}

install_common_package () {
    /bin/bash "$BASE_DIR/common/install_common_package.sh"
}

install_portable_tools () {
    /bin/bash "$BASE_DIR/tools/install_portable_tools.sh"
}

install_docker_binary () {
    /bin/bash "$BASE_DIR/docker/install_docker_binary.sh $BASE_DIR/docker/docker-20.10.9.tgz"
}

# 申请 sudo 权限
sudo command

# 测试 dialog 是否存在
which dialog > /dev/null 2>&1
# 不存在则安装
if [[ "0" -ne "$?" ]]; then
    sudo yum install -y "$BASE_DIR"/sub_scripts/dialog*.rpm > /dev/null
fi

# 遍历所有的命令项，生成菜单参数
for tag in ${ITEM_TAG_ARRAY[@]}; do
    item_list="${item_list} ${tag} '${ITEM_DESC_ARRAY[${tag}]}' '${ITEM_STATUS_ARRAY[${tag}]}' "
done


user_input=$(echo "$item_list" | xargs dialog --stdout --title "Function List" \
                --backtitle "System Initialization" \
                --checklist "Select the function item you need:" 13 60 6)

# 解析用户输入
user_input_array=($user_input)

# 用户取消输入则退出
if [[ "0" -ne "$?" ]]; then
    clear
    echo "User cancels the operation."
    exit 1
fi

clear
for i in ${user_input_array[@]}; do
    echo "${ITEM_CMD_ARRAY[$i]}"
done

