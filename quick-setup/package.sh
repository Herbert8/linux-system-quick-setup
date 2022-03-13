#!/bin/bash


# 获取 shell 脚本绝对路径
base_dir () { (cd "$(dirname "${BASH_SOURCE[0]}")"; pwd;) }

# 引入文件相关功能
source "$(base_dir)/sub_scripts/file_utils.sh"

# 要生成的安装包名称
readonly package_basename='install.sh'
readonly installer_package="$(base_dir)/$package_basename"

# 打包
tar_files () {
    tar --exclude=.DS_Store \
        --exclude=package.sh \
        --exclude=pkg.tar.gz \
        --exclude=sub_scripts \
        --exclude=test \
        --exclude="$package_basename" \
        -zcvf - *
}

# --exclude=docker \
# --exclude=tools \

# 获得 安装脚本文件模板 的位置
readonly install_script_template="$(base_dir)/sub_scripts/install_script.template"

# 将所有需要的脚本整合成一个字符串
scripts_str=$(cat "$(base_dir)/sub_scripts/file_utils.sh" \
    "$(base_dir)/sub_scripts/output_utils.sh" \
    "$(base_dir)/sub_scripts/installer_code.sh")

# 去掉脚本字符串中的 注释、空行，以及一些指定的不需要的行
scripts_str=$(echo "$scripts_str" | clear_invalid_line)

# 把脚本字符串做 Base64 编码
scripts_base64=$(echo "$scripts_str" | base64)

# 将模板读入字符串变量
installer_template=$(cat "$(base_dir)/sub_scripts/install_script.template")
# 使用前面 脚本字符串的 Base64 编码 替换模板中的占位符
installer_template="${installer_template//<SCRIPTS_PLACEHOLDER>/${scripts_base64}}"

# 将替换后的模板 生产 安装器
echo "$installer_template" > "$installer_package"

# 将 Dialog 组件 存入安装器
# cat "$(base_dir)/sub_scripts/dialog.rpm" | data_to_block_in_bash_script 'Dialog' >> "$installer_package"
(cd "$(base_dir)/sub_scripts/dialog"; tar zcvf - dialog libdialog.so.11) \
                    | data_to_block_in_bash_script 'Dialog' \
                    >> "$installer_package"

tar_files | data_to_block_in_bash_script 'System Setup Package' >> "$installer_package"

server_str='bahb@192.168.200.99'
server_path='/home/bahb/tmp/'
echo Uploading "'$installer_package'" to "'$server_str:$server_path'..."
sshpass -p 1 ssh "$server_str" "rm -rf '$server_path'; mkdir -p '$server_path'"
sshpass -p 1 scp -r "$installer_package" "$server_str:$server_path"
echo Complete.

