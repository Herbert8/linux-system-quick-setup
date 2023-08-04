#!/bin/bash

# 获取当前脚本所在位置
REAL_SCRIPT_FILE=$(readlink -f "${BASH_SOURCE[0]}")
BASE_DIR=$(dirname "$REAL_SCRIPT_FILE")
readonly REAL_SCRIPT_FILE
readonly BASE_DIR

REDIS_ROOT=$(readlink -f "$BASE_DIR/../..")
REDIS_WORKSPACE=$REDIS_ROOT/workspace

mkdir -p "$REDIS_WORKSPACE"

CMD_NAME=$(basename "${BASH_SOURCE[0]}")


redis_server_master () {
    (
        cd "$REDIS_ROOT" && "$REDIS_ROOT/bin/redis-server" "$REDIS_ROOT/conf/redis_master.conf"
    )
}

redis_server_slave () {
    (
        cd "$REDIS_ROOT" && "$REDIS_ROOT/bin/redis-server" "$REDIS_ROOT/conf/redis_slave.conf"
    )
}

redis_server_sentinel () {
    (
        cd "$REDIS_ROOT" && "$REDIS_ROOT/bin/redis-server" "$REDIS_ROOT/conf/redis_sentinel.conf" --sentinel
    )
}

case "${CMD_NAME}" in
    'rdsmaster')
        redis_server_master
    ;;
    'rdsslave')
        redis_server_slave
    ;;
    'rdssentinel')
        redis_server_sentinel
    ;;
    *)
        "$REDIS_ROOT/bin/redis-server" "$@"
    ;;
esac

