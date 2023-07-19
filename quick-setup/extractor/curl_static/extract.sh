#!/bin/bash

# 参考 static-curl 编译
# https://github.com/moparisthebest/static-curl

# 此脚本基于 Docker 运行，需要具备 Docker 环境

set -eu

# 查找用于构建 vim 的镜像
BUILD_CURL_ENV_IMG_NAME='curl-build-env'
BUILD_CURL_ENV_IMG_TAG='latest'

prepare_compile_image () {

    # 如果没有找到则进行镜像构建
    if ! docker images | grep "^${BUILD_CURL_ENV_IMG_NAME}\s*${BUILD_CURL_ENV_IMG_TAG}\s*"; then
        docker build \
        --build-arg http_proxy=$PROXY_SERVER \
        --build-arg https_proxy=$PROXY_SERVER \
        -t "${BUILD_CURL_ENV_IMG_NAME}:${BUILD_CURL_ENV_IMG_TAG}" - << EOF
FROM alpine:latest
RUN apk add gnupg build-base clang openssl-dev nghttp2-dev nghttp2-static \
            libssh2-dev libssh2-static openssl-libs-static zlib-static \
            autoconf automake libtool
EOF
    fi

}

main() {

    # 获取当前脚本所在位置
    BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    readonly BASE_DIR

    # 清理输出目录
    OUTPUT_PATH=$BASE_DIR/out
    mkdir -p "$OUTPUT_PATH"
    rm -rf "${OUTPUT_PATH:?}"/*

    # curl 版本
    CURL_VERSION='8.1.2'
    # CPU 架构
    ARCH=amd64

    PROXY_SERVER=http://192.168.50.100:8888

    prepare_compile_image

    TMP_WORK_DIR=$(mktemp -d)
    if git clone "https://github.com/moparisthebest/static-curl.git" "$TMP_WORK_DIR"; then
        # 在 Docker 中编译 curl
        docker run -i --rm \
            -e ARCH=$ARCH \
            -v "$TMP_WORK_DIR":/tmp \
            -w /tmp "${BUILD_CURL_ENV_IMG_NAME}:${BUILD_CURL_ENV_IMG_TAG}" /tmp/build.sh "$CURL_VERSION"

        # 收集编译结果
        [[ -f "$TMP_WORK_DIR/release/curl-$ARCH" ]] && cp "$TMP_WORK_DIR/release/curl-$ARCH" "$OUTPUT_PATH/curl-$ARCH-$CURL_VERSION"
    fi

    # 清理
    rm -rf "$TMP_WORK_DIR"
}

main "$@"

