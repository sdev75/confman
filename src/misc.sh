
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

Options:
  -h, --help      Prints this message
  -f, --file      Configuration file to read
  --parse         Parse and print configuration then exit
")

errmsg(){
  exec 1>&2
  echo -e "${RED}$1${NOCOLOR}"
}

help(){
  echo "${HELPTEXT[0]}"
  exit "$1"
}
