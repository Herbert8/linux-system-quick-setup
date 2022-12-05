# Bash tips: Colors and formatting (ANSI/VT100 Control sequences)
# https://misc.flogisoft.com/bash/tip_colors_and_formatting

TEXT_RESET_ALL_ATTRIBUTES=0

# ************ 文字 ***************
TEXT_BOLD_BRIGHT=1
TEXT_DIM=2
TEXT_UNDERLINED=4
TEXT_BLINK=5
TEXT_REVERSE=7
TEXT_HIDDEN=8

TEXT_RESET_BOLD_BRIGHT=21
TEXT_RESET_DIM=22
TEXT_RESET_UNDERLINED=24
TEXT_RESET_BLINK=25
TEXT_RESET_REVERSE=27
TEXT_RESET_HIDDEN=28

# ************ 颜色 ***************
# 前景色
COLOR_F_DEFAULT=39
COLOR_F_BLACK=30
COLOR_F_RED=31
COLOR_F_GREEN=32
COLOR_F_YELLOW=33
COLOR_F_BLUE=34
COLOR_F_MAGENTA=35
COLOR_F_CYAN=36
COLOR_F_LIGHT_GRAY=37
COLOR_F_DARK_GRAY=90
COLOR_F_LIGHT_RED=91
COLOR_F_LIGHT_GREEN=92
COLOR_F_LIGHT_YELLOW=93
COLOR_F_LIGHT_BLUE=94
COLOR_F_LIGHT_MAGENTA=95
COLOR_F_LIGHT_CYAN=96
COLOR_F_WHITE=97

# 背景色
COLOR_B_DEFAULT=49
COLOR_B_BLACK=40
COLOR_B_RED=41
COLOR_B_GREEN=42
COLOR_B_YELLOW=43
COLOR_B_BLUE=44
COLOR_B_MAGENTA=45
COLOR_B_CYAN=46
COLOR_B_LIGHT_GRAY=47
COLOR_B_DARK_GRAY=100
COLOR_B_LIGHT_RED=101
COLOR_B_LIGHT_GREEN=102
COLOR_B_LIGHT_YELLOW=103
COLOR_B_LIGHT_BLUE=104
COLOR_B_LIGHT_MAGENTA=105
COLOR_B_LIGHT_CYAN=106
COLOR_B_WHITE=107

# 网卡接口
PROMPT_NETWORK_INTERFACE='#######_NETWORK_DEVICE_#######'

# 颜色相关 API ******************************************************************

# 重置颜色设置
print_color_reset () {
    echo -ne "\033[0m"
}

# 使用指定颜色打印文字
# 颜色值通过前面的参数指定，最后一个参数指定输入文字
print_color () {
    for color in "$@"; do
        echo -ne "\033[${color}m"
    done
}

# 生成彩色文本
sprint_colored_text () {
    local attrs=''
    [[ "$#" -gt "1" ]] && for (( i=2;i<=$#;i++ )); do
        attrs=${attrs}${!i}';'
    done
    local msg=${1-}
    echo -n "\033[0;${attrs}m${msg}"
}
export -f sprint_colored_text

# 打印彩色文本
print_colored_text () {
    echo -ne "$(sprint_colored_text "$@")"
}
export -f print_colored_text

# 打印彩色文本后换行
println_colored_text () {
    print_colored_text "$@"
    echo
}
export -f println_colored_text

# 定义表示各个部分的值和颜色 *******************************************************
prompt_user () {
    if [[ "$PRODUCTION_ENV" == true ]]; then
        print_colored_text '\u' $COLOR_F_GREEN
    else
        print_colored_text '\u' $COLOR_F_GREEN $TEXT_BOLD_BRIGHT
    fi
}

prompt_at () {
    print_colored_text '@'
}

prompt_host () {
    print_colored_text '\H' $COLOR_F_CYAN $TEXT_BOLD_BRIGHT
}

# 获取 IP 的命令
get_ip_addr () {
    local local_ip
    local_ip=$(ip address show ${PROMPT_NETWORK_INTERFACE} | sed -nr 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
    local_ip=${local_ip/$'\n'/ }
    echo "$local_ip"
}

prompt_ip_addr () {
    print_colored_text "[$(get_ip_addr)]" $COLOR_F_CYAN $TEXT_BOLD_BRIGHT
}

prompt_colon () {
    print_colored_text ':'
}

prompt_current_path () {
    print_colored_text '\w' $COLOR_F_YELLOW $TEXT_BOLD_BRIGHT
}

# 获取日期的命令
get_date_time () { date "+%Y-%m-%d %H:%M:%S %z"; }

prompt_date_time () {
    print_colored_text "$(get_date_time)" $COLOR_F_DEFAULT $TEXT_DIM
}

# 获取代理设置
prompt_http_proxy () {
    print_colored_text "${http_proxy-}" $COLOR_F_CYAN $TEXT_DIM
}

prompt_https_proxy () {
    print_colored_text "${https_proxy-}" $COLOR_F_YELLOW $TEXT_DIM
}

# PROMPT_ALL_PROXY="${PROMPT_COLOR_BLUE_DIM}\${all_proxy}"
prompt_all_proxy () {
    print_colored_text "${all_proxy-}" $COLOR_F_BLUE $TEXT_DIM
}

prompt_char () {
    print_colored_text '\n\$ '
}

prompt_prod_tag () {
    if [[ "$PRODUCTION_ENV" == true ]]; then
        print_colored_text '[' $COLOR_F_LIGHT_YELLOW $TEXT_BOLD_BRIGHT
        print_colored_text '=PRODUCTION=' $COLOR_F_LIGHT_RED $TEXT_BOLD_BRIGHT
        print_colored_text ']' $COLOR_F_LIGHT_YELLOW $TEXT_BOLD_BRIGHT
        print_colored_text '-'
    else
        print_colored_text ''
    fi
}

PRODUCTION_ENV=false

# 设置提示风格
PS1="$(prompt_prod_tag)$(prompt_user)$(prompt_at)$(prompt_host)$(prompt_ip_addr)$(prompt_colon)$(prompt_current_path) \$(prompt_date_time) \$(prompt_http_proxy) \$(prompt_https_proxy) \$(prompt_all_proxy)$(prompt_char)"


