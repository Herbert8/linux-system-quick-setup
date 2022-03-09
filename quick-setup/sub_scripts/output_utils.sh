

# 定义基本颜色值
readonly TEXT_RESET_ALL_ATTRIBUTES=0
readonly TEXT_BOLD_BRIGHT=1
readonly TEXT_UNDERLINED=4
readonly COLOR_F_RED=31
readonly COLOR_F_LIGHT_RED=91

# 定义输出颜色
readonly STYLE_TITLE="\033[${TEXT_RESET_ALL_ATTRIBUTES}m\033[${TEXT_BOLD_BRIGHT}m\033[${TEXT_UNDERLINED}m"
readonly STYLE_PLAIN="\033[${TEXT_RESET_ALL_ATTRIBUTES}m"
readonly STYLE_IMPORTANT_TITLE="\033[${TEXT_RESET_ALL_ATTRIBUTES}m\033[${TEXT_BOLD_BRIGHT}m\033[${COLOR_F_RED}m"
readonly STYLE_IMPORTANT_PLAIN="\033[${TEXT_RESET_ALL_ATTRIBUTES}m\033[${COLOR_F_LIGHT_RED}m"

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

