port ${SENTINEL_PORT}
daemonize yes
dir ${WORK_DIR}/
pidfile ${WORK_DIR}/sentinel_${SENTINEL_PORT}.pid
logfile "sentinel_${SENTINEL_PORT}.log"

sentinel monitor mymaster ${MASTER_NODE_HOST} ${MASTER_NODE_PORT} 2
sentinel auth-pass mymaster ${MASTER_PASSWORD}
sentinel down-after-milliseconds mymaster 30000
sentinel parallel-syncs mymaster 1
sentinel failover-timeout mymaster 180000
