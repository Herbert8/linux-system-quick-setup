#!/bin/bash


# 获取 shell 脚本绝对路径
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly BASE_DIR


# 安装基础组件 *******************************************************************
sudo yum install -y "$BASE_DIR"/packages/**/*.rpm


