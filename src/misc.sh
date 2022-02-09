
declare -r BLACK='\033[0;30m'
declare -r RED='\033[0;31m'
declare -r GREEN='\e[0;32m'
declare -r ORANGE='\e[0;33m'
declare -r BLUE='\e[0;34m'
declare -r PURPLE='\e[0;35m'
declare -r CYAN='\e[0;36m'
declare -r LIGHT_GRAY='\e[0;37m'
declare -r NOCOLOR='\e[0m'

declare -a HELPTEXT=("
Usage ${0} [OPTIONS]

Global Options:
  -h, --help      Prints this message
  -f, --file      Configuration file to read
      --parse     Parse configuration, print it then exit

Snapshot Commands:
  mk, create      Usage: ${0} mk [name [tag [namespace]]]
  ls, list        Usage: ${0} ls [name [tag [namespace]]]
  rm, remove      Usage: ${0} rm [name [tag [namespace]]]
  cp, copy        Usage: ${0} cp [name [tag [namespace]]] destdir
  rr, restore     Usage: ${0} rr filename [name [tag [namespace]]]

Snapshot Options:
  -t, --tag       Set snapshot tag value
  -n, --ns        Set snapshot namespace value
")

errmsg(){
  exec 1>&2
  echo -e "${RED}$1${NOCOLOR}"
}

help(){
  echo "${HELPTEXT[0]}"
  exit "$1"
}
