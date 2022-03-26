

# 接收管道传入的数据
# 提取指定的两个字符串中间的数据
# $1   数据开始边界符
# $2   数据结束边界符
# full_text_extract () {
#     sed ":tag;N;s/\n/_n1234567890987654321n_/;b tag" \
#     | sed -nr "s/.*$1(.*)$2.*/\1/p" \
#     | sed 's/_n1234567890987654321n_/\n/g'
# }

# 接收管道传入的数据，做 Base64 编码
# 形成以下格式数据：
# -----BEGIN BLOCK_NAME-----
# Base64 Data
# -----END BLOCK_NAME-----
# $1   指定 Block Name
data_to_base64_block () {
    local block_name
    block_name="$1"
    base64 -w 76 | cat <(echo -e "\n-----BEGIN ${block_name^^}-----") - <(echo "-----END ${block_name^^}-----")
}

# 接收管道传入的数据，提取指定字符中间的数据
# $1   指定 Block Name
# extract_block () {
#     local block_name
#     block_name="$1"
#     full_text_extract "-----BEGIN ${block_name^^}-----" "-----END ${block_name^^}-----"
# }

# 数据放到 Bash 脚本中
# 先 Base64，然后在行首加上 '# '
data_to_block_in_bash_script () {
    data_to_base64_block "$1" | sed 's/^/# /g'
}


# 获取指定内容所在行号
get_line_index () {
    grep -n -- "$1" | awk -F : '{ print $1 }'
}

# 根据内容 起始、结束 的标记，提取内容
# $1 块名
# $2 从哪个文件提取
extract_block () {

    local start_line
    start_line=$(get_line_index "-----BEGIN ${1^^}-----" < "$2")
    local end_line
    end_line=$(get_line_index "-----END ${1^^}-----" < "$2")

    start_line=$((start_line + 1))
    end_line=$(( end_line - 1))

    sed -n "${start_line},${end_line}p" < "$2"
}



# 从 Bash 脚本中，根据内容 起始、结束 的标记，提取内容，然后去掉行首，Base64 反编码，得到原始内容
# $1 块名
# $2 从哪个文件提取
extract_block_from_bash_script () {
    extract_block "$1" "$2" | sed 's/[# ]//g' | base64 -d
}

tar_files_in_directory () {
    if [[ -d "$1" ]]; then
        (cd "$1" || return; tar zcv -- *)
    else
        >&2 echo "The 'tar' command failed to execute. Directory '$1' does not exist."
    fi
}

clear_invalid_line () {
    sed '/^[ \t]*#/d' \
    | sed '/^alias/d' \
    | sed '/^debug/d' \
    | sed '/^\s*$/d'
}


clear_file () {
    clear_invalid_line < "$1" > "$1".tmp
    rm "$1"
    mv "$1".tmp "$1"
}


