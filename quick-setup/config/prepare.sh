#!/bin/bash


# 获取 shell 脚本绝对路径
 BASE_DIR=$(dirname "${BASH_SOURCE[0]}")
 readonly BASE_DIR

# 加载输出相关函数
source "$BASE_DIR/../sub_scripts/output_utils.sh"


# 选择数据根路径
storage_mount_point=$(dialog --stdout --title "Data Storage Mount Point" \
                        --backtitle 'System Initialization' \
                        --dselect "/" 12 60)

dialog_ret="$?"
# 用户取消输入则退出
if [[ "0" -ne "$dialog_ret" ]]; then
    clear
    echo "User cancels the operation."
    exit 1
fi

# 挂在点不存在则退出
if [[ ! -d "$storage_mount_point" ]]; then
    echo "Mount point does not exist."
    exit 1
fi

field_user_name='moa'
field_docker_group_id='10000'

# 输入基础信息
form_input=$(dialog --stdout --title "Setup System Information" \
                --backtitle 'System Initialization' \
                --form "Please input the infomation to initialize the system:" 10 75 3  \
                "User Name:"       1  2  "${field_user_name}"        1  19  50  0  \
                "Docker Group ID:" 3  2  "${field_docker_group_id}"  3  19  50  0)

dialog_ret="$?"
# 用户取消输入则退出
if [[ "0" -ne "$dialog_ret" ]]; then
    clear
    echo "User cancels the operation."
    exit 1
fi

# 输入的表单信息放入熟组
IFS=$'\n' read -ra form_input_array <<< "$form_input"

# 表单信息拆分到变量
field_user_name="${form_input_array[0]}"
field_docker_group_id="${form_input_array[1]}"

user_name=${field_user_name}
group_name="${user_name}"

user_home_dir="${storage_mount_point}/${user_name}/"
user_home_dir="${user_home_dir//\/\//\/}"

# 显示用户输入信息
clear
print_title '[Input Information]\n'
cat << EOF | column -t -s +
Data Storage Mount Point:+[${storage_mount_point}]
User Name:+[${user_name}]
User Home Directory:+[${user_home_dir}]
Group Name:+[${group_name}]
Docker Group ID:+[${field_docker_group_id}]
EOF

# 提示用户确认信息
echo
# 确认信息大写
typeset -u user_choice
read -rp 'Is this ok [y/N]: ' user_choice
# 去掉无用空格
user_choice=$(echo "$user_choice" | xargs)

# 判断用户输入
if [[ 'Y' != "$user_choice" ]]; then
    echo 'Please reconfirm the information and execute the script again.'
    exit 1
fi


app_data="${storage_mount_point}/app_data"
app_data="${app_data//\/\//\/}"

# 创建用户、用户组
echo
print_title 'The following commands will be executed:\n'
cat << EOF

# Create user and group
sudo useradd  -d ${user_home_dir} ${user_name}
sudo groupadd -g ${field_docker_group_id} docker
sudo gpasswd  -a ${user_name} docker

# Create directories
sudo mkdir -p "${app_data}"
sudo mkdir -p "${app_data}/nginx/logs"
sudo mkdir -p "${app_data}/nginx/shared/webroot"
sudo mkdir -p "${app_data}/nginx/conf.d/locations"
sudo mkdir -p "${app_data}/nginx/conf.d/ssl"
sudo mkdir -p "${app_data}/nginx/conf.d/script/jwt"
sudo mkdir -p "${app_data}/nginx/conf.d/script/crontab"
sudo mkdir -p "${app_data}/minio/d1"
sudo mkdir -p "${app_data}/minio/d2"
sudo mkdir -p "${app_data}/minio/d3"
sudo mkdir -p "${app_data}/minio/logs"
sudo mkdir -p "${app_data}/redis/conf/16379"
sudo mkdir -p "${app_data}/redis/conf/26379"
sudo mkdir -p "${app_data}/redis/data/16379"
sudo mkdir -p "${app_data}/redis/data/26379"
sudo mkdir -p "${app_data}/server/logs"
sudo mkdir -p "${app_data}/server/temp"
sudo mkdir -p "${app_data}/server/conf"

# Change app data directory owner
sudo chown -R ${user_name}:${group_name} "${app_data}"
==========================================================================
EOF

# 提示用户确认信息
# 确认信息大写
typeset -u user_choice
read -rp 'Are you sure you want to execute these commands [y/N]: ' user_choice
# 去掉无用空格
user_choice=$(echo "$user_choice" | xargs)

# 判断用户输入
if [[ 'Y' != "$user_choice" ]]; then
    echo 'Please reconfirm the information and execute the script again.'
    exit 1
fi



