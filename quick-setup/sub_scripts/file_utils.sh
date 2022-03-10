
# 接收管道传入的数据
# 提取指定的两个字符串中间的数据
# $1   数据开始边界符
# $2   数据结束边界符
full_text_extract () {
    sed ":tag;N;s/\n/_n1234567890987654321n_/;b tag" \
    | sed -nr "s/.*$1(.*)$2.*/\1/p" \
    | sed 's/_n1234567890987654321n_/\n/g'
}

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
    # base64 | cat <(echo -e "\n-----BEGIN ${block_name^^}-----") - <(echo "-----END ${block_name^^}-----")
}

# 接收管道传入的数据，提取指定字符中间的数据
# $1   指定 Block Name
extract_block () {
    local block_name
    block_name="$1"
    full_text_extract "-----BEGIN ${block_name^^}-----" "-----END ${block_name^^}-----"
}
