#!bash


# 获取 shell 脚本绝对路径
base_dir () { (cd "$(dirname "${BASH_SOURCE[0]}")"; pwd;) }
readonly BASE_DIR=$(base_dir)

if [[ "Linux" != "$(uname)" ]]; then
    echo OS must be Linux.
    exit 1
fi

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
    bash "$BASE_DIR/config/install_config.sh"
}

install_common_package () {
    bash "$BASE_DIR/common/install_common_package.sh"
}

install_portable_tools () {
    bash "$BASE_DIR/tools/install_portable_tools.sh"
}

install_docker_binary () {
    bash "$BASE_DIR/docker/install_docker_binary.sh" "$BASE_DIR/docker/docker-20.10.9.tgz"
}


# 遍历所有的命令项，生成菜单参数
for tag in ${ITEM_TAG_ARRAY[@]}; do
    item_list="${item_list} ${tag} '${ITEM_DESC_ARRAY[${tag}]}' '${ITEM_STATUS_ARRAY[${tag}]}' "
done

export LD_LIBRARY_PATH="$(base_dir)"
user_input=$(echo "$item_list" | xargs "$(base_dir)/dialog" --stdout --title "System Configuration Menu" \
                --backtitle "System Initialization" \
                --checklist "Select the function item you need:" 13 60 6)

dialog_ret="$?"
# 用户取消输入则退出
if [[ "0" -ne "dialog_ret" ]]; then
    clear
    echo "User cancels the operation."
    exit 1
fi

# 解析用户输入
user_input_array=($user_input)


clear
for user_selected_item in ${user_input_array[@]}; do
    ${ITEM_CMD_ARRAY[$user_selected_item]}
done

