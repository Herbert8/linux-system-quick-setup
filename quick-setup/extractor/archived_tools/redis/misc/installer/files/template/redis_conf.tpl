# server
port ${PORT}
daemonize yes
dir ${WORK_DIR}/
pidfile redis_${PORT}.pid
loglevel notice
logfile "${LOG_FILE_NAME}"
databases 16
dbfilename ${RDB_FILE_NAME}
requirepass ${PASSWORD}

# aof
appendonly yes
appendfilename "${AOF_FILE_NAME}"
appendfsync everysec
no-appendfsync-on-rewrite yes
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
aof-rewrite-incremental-fsync yes

# 从节点打开注释
### replicaof ${MASTER_NODE_HOST} ${MASTER_NODE_PORT}
### masterauth ${MASTER_PASSWORD}
### replica-read-only yes
