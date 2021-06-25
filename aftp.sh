#!/bin/bash
set -f
# 配置文件，指定下列配置默认值，若命令行中传递对应参数则覆盖配置文件中相应的配置
fpt_conf=
# 认证信息
ftp_host=
ftp_port=21
ftp_user=
ftp_pass=
# 本地工作目录(ftp>lcd)，push-从该目录寻找文件上传; pull-文件下载到该目录
ftp_local=
# 远程工作目录(ftp>cd)，push-文件上传到该目录; pull-从该目录寻找文件下载
ftp_remote=
# 传输模式，ascii|binary
ftp_transfer_mode=ascii

function usage() {
  cat << 'EOF'
Usage: aftp COMMAND [OPTS...] [ARGS...]

  FTP client non interactive command line script.

Commands:
  push            Push one or more files to FTP server
  pull            Pull one or more files from FTP server
  exec            Execute the command on the FTP server
  ls              List the contents of FTP server directory

Run 'aftp help COMMAND' for more details on a command.
EOF
}

function usage_ls() {
  cat << 'EOF'
Usage: aftp ls -h host [-p port] -u user [-P password] [DIR(default /)]

  List the contents of FTP server directory.

Options:
  -h            FTP server host name
  -p            FTP server port(default 21)
  -P            User password
  -u            User name
EOF
}

function usage_exec() {
  cat << 'EOF'
Usage: aftp exec -h host [-p port] -u user [-P password] COMMAND

  Execute the command on the FTP server.

Options:
  -h            FTP server host name
  -p            FTP server port(default 21)
  -P            User password
  -u            User name
EOF
}

function usage_push() {
  cat << 'EOF'
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
EOF
}

function usage_pull() {
  cat << 'EOF'
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
EOF
}

# 通知
# $1 通知类型
# $2 通知内容
function dialog() {
  case $1 in
    fatal) printf '%s\n' "$2" && exit 1;;
    error) printf '%s\n\n%s\n' "$2" 'For more details, see "aftp help".' && exit 1;;
    info)  printf '%s\n' "$2";;
    ok)    echo 'OK.';;
    exit)  echo 'exited.';;
  esac
  exit 0
}

# 判断数组是否包含某元素
# $1     被检查元素
# $2...  数组
function array_has() {
  test $# -lt 2 && return 1
  sub=$1 && shift
  echo $@ | sed 's/ /\'$'\n/g' | xargs -I % bash -c "test % == $sub && echo 0 || echo 1" | grep 0 &> /dev/null
}

# args 解析，获取文件 basename
function args() {
  echo $@ | sed 's/ /\'$'\n/g' | xargs -I % basename % | tr '\n' ' '
}

function opts_lr() {
  test $# -lt 1 && dialog error 'Requires at least one file as the argument.'
  test -z $ftp_local && dialog error 'Requires an option -l, specify the local working directory.'
  test -z $ftp_remote && dialog error 'Requires an option -r, specify the remote working directory.'
}

function opts_m() {
  test -z $1 && return
  array_has $1 ascii binary && ftp_transfer_mode=$1 || dialog error 'Invalid value for option -m, the transfer mode only be acsii or binary.'
}

# getopts 解析
# $@, opts... args...
# @return $?, 调用方 shift 剔除 getopts 参数数量
function opts() {
  while getopts 'h:p:u:P:l:r:m:' options; do
    case $options in
      # 认证信息
      h) host=$OPTARG;;
      p) port=$OPTARG;;
      u) user=$OPTARG;;
      P) pass=$OPTARG;;
      # 工作目录
      l) local=$OPTARG;;
      r) remote=$OPTARG;;
      # 传输模式
      m) mode=$OPTARG;;
    esac
  done
  test ! -z $host && ftp_host=$host || dialog error 'Requires an option -h, specify host.'
  test ! -z $port && ftp_port=$port
  test ! -z $user && ftp_user=$user || dialog error 'Requires an option -u, specify user.'
  test ! -z $pass && ftp_pass=$pass
  test ! -z $local && ftp_local=$local
  test ! -z $remote && ftp_remote=$remote
  opts_m $mode
  return $(($OPTIND - 1))
}

# 列出文件和目录
# aftp ls -h host [-p port] -u user [-P password] [DIR(default /)]
function ls() {
  opts $@ || shift $?
  ftp -inp << EOF
open $ftp_host $ftp_port
user $ftp_user $ftp_pass
$(test ! -z $1 && echo "cd $1")
ls
close
bye
EOF
}

# 执行 ftp 命令
# aftp exec -h host [-p port] -u user [-P password] COMMAND
function exec() {
  opts $@ || shift $?
  test $# -le 0 && dialog error 'Requires one command as the argument.'
  ftp -inp << EOF
open $ftp_host $ftp_port
user $ftp_user $ftp_pass
$@
close
bye
EOF
}

# 批量上传
# aftp push -h host [-p port] -u user [-P password] [-m transfer_mode] -l local_directory -r remote_directory files...
function push() {
  opts $@ || shift $?
  opts_lr $@
  ftp -inp << EOF &> /dev/null
open $ftp_host $ftp_port
user $ftp_user $ftp_pass
lcd $ftp_local
cd $ftp_remote
$ftp_transfer_mode
mput $(args $@)
close
bye
EOF
}

# 批量下载
# aftp pull -h host [-p port] -u user [-P password] [-m transfer_mode] -l local_directory -r remote_directory files...
function pull() {
  opts $@ || shift $?
  opts_lr $@
  ftp -inp << EOF &> /dev/null
open $ftp_host $ftp_port
user $ftp_user $ftp_pass
lcd $ftp_local
cd $ftp_remote
$ftp_transfer_mode
mget $(args $@)
close
bye
EOF
}

function help() {
  test -z $1 && usage && exit
  type -t usage_$1 &> /dev/null && usage_$1 || dialog error "$1: command not found."
}

# main
test ! -x "$(command -v ftp)" && dialog fatal 'ftp: command not found.'
case $1 in
  ls) shift && ls $@;;
  exec) shift && exec $@;;
  push) shift && push $@;;
  pull) shift && pull $@;;
  help) shift && help $1;;
  *) usage;;
esac