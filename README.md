# aftp
FTP 客户端非交互式命令行脚本

## 使用场景
- 边界接入服务中，为前/后置机与 ftp server 数据交换提供自动化脚本支持，帮助隔绝的两个网络实现基于文件的数据同步

## 功能列表
- 批量上传
- 批量下载
- 列出 ftp server 目录内容
- 发送命令至  fpt server 执行

## 依赖说明
- ftp

## 常见问题
- 使用 cron 定时调用该脚本下载文件时，如果文件超过 28M，文件下载中断（或不完整）问题

*直接 shell 执行没有遇到该问题，只有放到 cron 计划任务中执行时才会发生该问题（不确定其中的差异，可能是 cron、shell 调用之间的环境差异造成的，不排除 shell 调用在下载更大文件的时候也会遇到该问题）*
> 导致该问题的本质原因是 TCP 连接被操作系统超时关闭了。由于文件较大，下载时间较长，在这段时间内两端又没有任何交流，操作系统认为该 TCP 连接已无必要维持，故断开连接，导致文件下载中断（或不完整）

**解决问题的思路就是，保证 TCP 连接处于活跃状态而不被操作系统断开，需要修改 TCP keepalive 相关内核参数，如下**
```shell
# vim /etc/sysctl.conf                  # 修改 TCP keepalive 相关内核参数
net.ipv4.tcp_keepalive_time = 30        # 每间隔 30s 向对端发送一个 keepalive 心跳包，默认 7200s
net.ipv4.tcp_keepalive_intvl = 10       # 在发送 keepalive 心跳包后，如果没有接收到对端的确认包。则每间隔 10 秒继续发送 keepalive 心跳包，一共发送 tcp_keepalive_probes 次，默认 75s
net.ipv4.tcp_keepalive_probes = 6       # 在发送 keepalive 心跳包后，如果没有接收到对端的确认包。则每间隔 tcp_keepalive_intvl 秒继续发送 keepalive 心跳包，一共发送 6 次，默认 9 次

# 载入 sysctl 配置文件（重载内核配置，使上述改动生效）
sysctl -p
```
上述改动的意思就是，如果 TCP keepalive 保活功能开启，那么 TCP 连接建立后，每隔 30s 发送一个心跳包，如果对端没有回复，则继续每隔 10s 发送一次心跳包，重复 6 次如果还没有回复，则断开 TCP 连接
>只要 TCP 两端之间有数据包交换，则各自都会重置该连接上次接收数据包的时间，如此 keepalive 心跳包就可以不断的刷新这个时间，来避免超时，可以在 C/S 的任意一端或两端都开启 keepalive 保活功能

## 使用说明
```shell
Usage: aftp COMMAND [OPTS...] [ARGS...]

  FTP client non interactive command line script.

Commands:
  push            Push one or more files to FTP server
  pull            Pull one or more files from FTP server
  exec            Execute the command on the FTP server
  ls              List the contents of FTP server directory

Run 'aftp help COMMAND' for more details on a command.
```

## 批量上传
- 使用通配符上传，必须放在引号内，避免被提前扩展，如 "*.data"，否则通配符将被扩展，并且是基于当前目录的，而不是 ftp_local 本地工作目录
- 默认使用 ascii 文本传输模式上传，如果是图片、可执行文件等，则必须使用 binary 二进制传输模式上传
```shell
Usage: aftp push -h host [-p port] -u user [-P password] [-m transfer_mode] 
                 -l local_directory -r remote_directory files...

  Push one or more files to FTP server.

Options:
  -h            FTP server host name
  -l            Local working directory(lcd)
  -m            Set transfer mode(default "ascii", only be <ascii|binary>)
  -p            FTP server port(default 21)
  -P            User password
  -r            Remote working directory(cd)
  -u            User name
```

## 批量下载
- 使用通配符下载，必须放在引号内，避免被提前扩展，如 "*.data"，否则通配符将被扩展，并且是基于当前目录的，而不是 ftp_remote 远程工作目录
- 默认使用 ascii 文本传输模式下载，如果是图片、可执行文件等，则必须使用 binary 二进制传输模式下载
```shell
Usage: aftp pull -h host [-p port] -u user [-P password] [-m transfer_mode] 
                 -l local_directory -r remote_directory files...

  Pull one or more files from FTP server.

Options:
  -h            FTP server host name
  -l            Local working directory(lcd)
  -m            Set transfer mode(default "ascii", only be <ascii|binary>)
  -p            FTP server port(default 21)
  -P            User password
  -r            Remote working directory(cd)
  -u            User name
```

## 发送服务器命令
```shell
Usage: aftp exec -h host [-p port] -u user [-P password] COMMAND

  Execute the command on the FTP server.

Options:
  -h            FTP server host name
  -p            FTP server port(default 21)
  -P            User password
  -u            User name
```

## 列出服务器目录内容
```shell
Usage: aftp ls -h host [-p port] -u user [-P password] [DIR(default /)]

  List the contents of FTP server directory.

Options:
  -h            FTP server host name
  -p            FTP server port(default 21)
  -P            User password
  -u            User name
```
