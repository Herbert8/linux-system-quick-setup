
ptmux () {
    # 获取当前脚本所在位置
    local script_file
    script_file=$(readlink -f "${BASH_SOURCE[0]}")
    readonly script_file

    local base_dir
    base_dir=$(dirname "$script_file")
    readonly base_dir

    local tmux_root=$base_dir

    LD_LIBRARY_PATH=$tmux_root/lib64 "$tmux_root/bin/tmux" -f "$tmux_root/tmux.conf" "$@"
}
export -f ptmux
