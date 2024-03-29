#!/bin/bash

# 注意：本文件设计为在 macOS 上执行
# 所以 base64 和 tar 等命令使用了这些命令的 GNU 版本，就是 gbase64 和 gtar

# 获取 shell 脚本绝对路径
base_dir () { (cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); }

# 引入文件相关功能
source "$(base_dir)/sub_scripts/file_utils.sh"

# 要生成的安装包名称
readonly package_basename='tools_installer.sh'

dist_dir=$(base_dir)/dist
readonly dist_dir
mkdir -p "$dist_dir"

installer_package=$dist_dir/$package_basename
readonly installer_package

# 打包
tar_files () {
    gtar --exclude=.DS_Store \
        --exclude=package.sh \
        --exclude=pkg.tar.gz \
        --exclude=sub_scripts \
        --exclude=test \
        --exclude="$package_basename" \
        -zcv -- *
}

# --exclude=docker \
# --exclude=tools \

# 将所有需要的脚本整合成一个字符串
scripts_str=$(cat "$(base_dir)/sub_scripts/file_utils.sh" \
    "$(base_dir)/sub_scripts/output_utils.sh" \
    "$(base_dir)/sub_scripts/installer_code.sh")

# 去掉脚本字符串中的 注释、空行，以及一些指定的不需要的行
scripts_str=$(echo "$scripts_str" | clear_invalid_line)

# 把脚本字符串做 Base64 编码
scripts_base64=$(echo "$scripts_str" | gbase64)

# 将模板读入字符串变量
installer_template=$(clear_invalid_line < "$(base_dir)/sub_scripts/install_script.template")
# 使用前面 脚本字符串的 Base64 编码 替换模板中的占位符
installer_template="${installer_template//<SCRIPTS_PLACEHOLDER>/${scripts_base64}}"

{
    # 将替换后的模板 生产 安装器
    echo "$installer_template"

    # 将 Dialog 组件 存入安装器
    tar_files_in_directory "$(base_dir)/sub_scripts/dialog" \
                            | data_to_block_in_bash_script 'Dialog'

    # tar common 目录
    tar_files_in_directory "$(base_dir)/components/rpm" \
                            | data_to_block_in_bash_script 'RPM'

    # tar config 目录
    tar_files_in_directory "$(base_dir)/components/config" \
                            | data_to_block_in_bash_script 'Config'

    # tar docker 目录
    tar_files_in_directory "$(base_dir)/components/docker" \
                            | data_to_block_in_bash_script 'Docker'

    # tar portable_tools 目录
    tar_files_in_directory "$(base_dir)/components/portable_tools" \
                            | data_to_block_in_bash_script 'Portable Tools'

    # tar standalone_tools 目录
    tar_files_in_directory "$(base_dir)/components/standalone_tools" \
                            | data_to_block_in_bash_script 'Standalone Tools'
} > "$installer_package"


if ncat -w2 -zv 192.168.200.99 22; then
    server_str='bahb@192.168.200.99'
    server_path='/home/bahb/tmp/'
    echo Uploading "'$installer_package'" to "'$server_str:$server_path'..."
    sshpass -p 1 ssh "$server_str" "mkdir -p '$server_path'; rm -rf '$server_path'/*; "
    sshpass -p 1 scp -r "$installer_package" "$server_str:$server_path"
fi

echo Complete.

