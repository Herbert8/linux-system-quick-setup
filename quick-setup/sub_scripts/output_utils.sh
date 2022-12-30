

if [[ -n "$GLOBAL_TAG_OUTPUT_UTILS" ]]; then
    return
fi

GLOBAL_TAG_OUTPUT_UTILS=100

# 定义基本颜色值
readonly TEXT_RESET_ALL_ATTRIBUTES=0
readonly TEXT_BOLD_BRIGHT=1
readonly TEXT_DIM=2
readonly TEXT_UNDERLINED=4
readonly COLOR_F_RED=31
readonly COLOR_F_LIGHT_RED=91


# 定义输出颜色
readonly STYLE_TITLE="\033[${TEXT_RESET_ALL_ATTRIBUTES}m\033[${TEXT_BOLD_BRIGHT}m\033[${TEXT_UNDERLINED}m"
readonly STYLE_PLAIN="\033[${TEXT_RESET_ALL_ATTRIBUTES}m"
readonly STYLE_IMPORTANT_TITLE="\033[${TEXT_RESET_ALL_ATTRIBUTES}m\033[${TEXT_BOLD_BRIGHT}m\033[${COLOR_F_RED}m"
readonly STYLE_IMPORTANT_PLAIN="\033[${TEXT_RESET_ALL_ATTRIBUTES}m\033[${COLOR_F_LIGHT_RED}m"
readonly STYLE_DIM="\033[${TEXT_DIM}m"

print_title () {
    echo -ne "${STYLE_TITLE}$1${STYLE_PLAIN}"
}

print_plain () {
    echo -ne "${STYLE_PLAIN}$1${STYLE_PLAIN}"
}

print_important_title () {
    echo -ne "${STYLE_IMPORTANT_TITLE}$1${STYLE_PLAIN}"
}

print_important_plain () {
    echo -ne "${STYLE_IMPORTANT_PLAIN}$1${STYLE_PLAIN}"
}

print_dim_plain () {
    echo -ne "${STYLE_DIM}$1${STYLE_PLAIN}"
}

print_without_scroll_screen () {
    while read -r line; do echo -ne "\033[1K\r\033[2m$line"; done; echo -e "\033[0m"
}

# 清理前面输出的指定行数
clear_scroll_lines() {
    local lines_count=${1:-}
    [[ -z "$lines_count" ]] && return
    echo -ne "\033[${lines_count}A"
    for ((i = 0; i < lines_count; i++)); do
        echo -e "\033[K"
    done
    echo -ne "\033[${lines_count}A"
}

# 在指定范围内滚动
# 参考：https://zyxin.xyz/blog/2020-05/TerminalControlCharacters/
print_scroll_in_range() {
    # 默认最多显示滚动行数，默认为 8
    local scroll_lines=${1:-8}
    # 每行字符数，避免折行，默认 120
    local chars_per_line=${2:-120}
    local txt=''
    local last_line_count=0
    while read -r line; do
        line=${line:0:$chars_per_line}
        [[ "${last_line_count}" -gt "0" ]] && echo -ne "\033[${last_line_count}A"
        if [[ -z "$txt" ]]; then
            txt=$(echo -e "\033[2m$line\033[K" | tail -n"$scroll_lines")
        else
            txt=$(echo -e "$txt\n$line\033[K" | tail -n"$scroll_lines")
        fi
        last_line_count=$(($(wc -l <<<"$txt")))
        echo "$txt"
    done
    echo -ne "\033[0m"
    if [[ "$last_line_count" -gt "0" ]]; then
        clear_scroll_lines "$last_line_count"
    fi
}

