#!/bin/bash


# 获取 shell 脚本绝对路径
base_dir () { dirname "${BASH_SOURCE[0]}"; }
BASE_DIR=$(base_dir)


# 安装基础组件 *******************************************************************
sudo yum install -y "$BASE_DIR"/packages/**/*.rpm


