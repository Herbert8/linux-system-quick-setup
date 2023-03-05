
# 准备并创建目录
prepare_dir () {
    # 获取当前脚本所在位置
    BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
}

clear_dir () {
    unset BASE_DIR
}

main () {
    prepare_dir

    export PATH=$BASE_DIR/tool:$BASE_DIR/tool/tmux:$BASE_DIR/tool/vim:$PATH
    export LD_LIBRARY_PATH=$BASE_DIR/tool/lib64:$LD_LIBRARY_PATH

    # 执行配置
    source "$BASE_DIR/script/alias_function.sh"
    source "$BASE_DIR/script/bash_prompt_style.sh"

    alias vim="$BASE_DIR/tool/vim/vim"
    alias tmux="$BASE_DIR/tool/tmux/tmux"

    eval "$("$BASE_DIR/tool/zoxide" init bash)"

    clear_dir
}

main
