# 服务器配置说明



[TOC]

## 目录使用规范

- 文件存放位置

```
/opt/packages/ 存放安装包等
/opt/scripts/ 存放常用脚本
```



## 安装项



### 命令行提示符

1. 将 `bash_prompt_style.sh` 复制到 `/opt/scripts/`
2. 在 `/etc/profile.d/` 中创建 Symbolic Link

```bash
sudo ln -sf /opt/scripts/bash_prompt_style.sh /etc/profile.d/bash_prompt_style.sh
```



### 软件配置文件

- 通用 vim 配置

原始通用配置文件：`/etc/vimrc`

自定义通用配置文件：`/etc/vimrc_custom`

在原始文件中修改：

```
echo 'source /etc/vimrc_custom' | sudo tee -a /etc/vimrc
```

- 通用 tmux 配置

```
/etc/tmux.conf
```



### 安装常用工具

收集常用 rpm 包，通过本地安装

```bash
sudo yum install -y *.rpm
```



### 安装便携工具

1. 解压缩到

```
/opt/tools/
```

2. 创建 Symbolic Link

```
/usr/local/bin/
```



### 安装 Docker

1. 指定 Docker 数据的存储位置

```
原始默认位置
/var/lib/docker/

自定义默认位置
/srv/docker_data/

自定义位置：根据存储设置，指定容量大的位置，如：
/data/docker_data/
```

2. 解压缩到

```
/opt/docker/
```

3. 创建 Symbolic Link

```
/usr/bin/
```

4. 创建 Service



### 创建用户组

### 按是否使用 Docker 区分安装方式

源码编译

- Nginx
- Redis



开箱即用

- MinIO