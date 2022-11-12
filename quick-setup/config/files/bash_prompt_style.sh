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

# 定义颜色变量
PROMPT_COLOR_DEFAULT_RESET="\e[${COLOR_F_DEFAULT};${TEXT_RESET_ALL_ATTRIBUTES}m"
PROMPT_COLOR_DEFAULT_DIM="\e[${TEXT_RESET_ALL_ATTRIBUTES}m\e[${COLOR_F_DEFAULT};${TEXT_DIM}m"
PROMPT_COLOR_PINK_BOLD_BRIGHT="\e[${COLOR_F_MAGENTA};${TEXT_BOLD_BRIGHT}m"
PROMPT_COLOR_GREEN_BOLD_BRIGHT="\e[${COLOR_F_GREEN};${TEXT_BOLD_BRIGHT}m"
PROMPT_COLOR_BLUE_BOLD_BRIGHT="\e[${COLOR_F_BLUE};${TEXT_BOLD_BRIGHT}m"
PROMPT_COLOR_YELLOW_BOLD_BRIGHT="\e[${COLOR_F_YELLOW};${TEXT_BOLD_BRIGHT}m"
PROMPT_COLOR_CYAN_BOLD_BRIGHT="\e[${COLOR_F_CYAN};${TEXT_BOLD_BRIGHT}m"


PROMPT_COLOR_CYAN_DIM="\e[${TEXT_RESET_ALL_ATTRIBUTES}m\e[${COLOR_F_CYAN};${TEXT_DIM}m"
PROMPT_COLOR_YELLOW_DIM="\e[${TEXT_RESET_ALL_ATTRIBUTES}m\e[${COLOR_F_YELLOW};${TEXT_DIM}m"
PROMPT_COLOR_BLUE_DIM="\e[${TEXT_RESET_ALL_ATTRIBUTES}m\e[${COLOR_F_LIGHT_BLUE};${TEXT_DIM}m"



# 定义表示各个部分的值和颜色
PROMPT_USER=${PROMPT_COLOR_GREEN_BOLD_BRIGHT}'\u'
PROMPT_AT=${PROMPT_COLOR_DEFAULT_RESET}'@'
PROMPT_HOST=${PROMPT_COLOR_CYAN_BOLD_BRIGHT}'\H'

# 获取 IP 的命令
get_ip_addr () { ip address show ${PROMPT_NETWORK_INTERFACE} | sed -nr 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'; }
PROMPT_IP_ADDR="[${PROMPT_COLOR_CYAN_BOLD_BRIGHT}\$(get_ip_addr)]"
PROMPT_COLON=${PROMPT_COLOR_DEFAULT_RESET}':'
PROMPT_CUR_PATH=${PROMPT_COLOR_YELLOW_BOLD_BRIGHT}'\w'

# 获取日期的命令
get_date_time () { date "+%Y-%m-%d %H:%M:%S %z"; }
PROMPT_DATE_TIME="${PROMPT_COLOR_DEFAULT_DIM}[\$(get_date_time)]"

# 获取代理设置
PROMPT_HTTP_PROXY="${PROMPT_COLOR_CYAN_DIM}\${http_proxy}"
PROMPT_HTTPS_PROXY="${PROMPT_COLOR_YELLOW_DIM}\${https_proxy}"
PROMPT_ALL_PROXY="${PROMPT_COLOR_BLUE_DIM}\${all_proxy}"

PROMPT_CHAR="${PROMPT_COLOR_DEFAULT_RESET}"'\n\$ '

# 设置提示风格
PS1="${PROMPT_USER}${PROMPT_AT}${PROMPT_HOST}${PROMPT_IP_ADDR}${PROMPT_COLON}${PROMPT_CUR_PATH} ${PROMPT_DATE_TIME} ${PROMPT_HTTP_PROXY} ${PROMPT_HTTPS_PROXY} ${PROMPT_ALL_PROXY}${PROMPT_CHAR}"
