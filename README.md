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

## 
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