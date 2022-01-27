#!/usr/bin/env sh

#include misc.sh
#include cfg.sh
#include confman.sh
#include snapshot.sh

# Set default cachedir 
# default value to ~/.cache/confman
# Its possible to pass the value by ENV using CACHEDIR=. confman
if [ -z ${CACHEDIR+x} ]; then
  CACHEDIR=$HOME/.cache/confman
fi

cache_init(){
  # CacheDir must exists to operate correctly
  if [ ! -d $CACHEDIR ]; then
    read -rep "$CACHEDIR does not exist. Would you like to create it? (y/n)" -n 1
    if echo $REPLY | grep -Eq '[yY]'; then
      mkdir -p $CACHEDIR
    else
     errmsg "$CACHEDIR is required to use this program" 
     exit 1
    fi
  fi

  # Ge the absolute path and compare it with current working directory
  CACHEDIR=$(realpath "$CACHEDIR")
  if [ "$CACHEDIR" = "$(pwd)" ]; then
    errmsg "In sourcing disabled"
    exit 1
  fi
}

checksum(){
  local res=$(sha256sum "$1" | awk 'print $1}')
  return $res
}

init_flags(){
  cfg_setflags opts 0
  readonly F_CONFMAN_FILE=$((1 << 0))
  readonly F_CONFIG_PRINT=$((2 << 0))
}

init_parseopts(){
  local shortargs longargs opts
  shortargs="hf:"
  longargs="help,file:,parse"
  opts=$(getopt -o $shortargs --long $longargs -- "$@")
  if [ $(( $? )) -ne 0 ]; then
    exit $?
  fi

  eval set -- "$opts"
  while true; do
    case "$1" in
      -h|--help)
        help 0
        ;;
      --parse)
        cfg_setflags opts $F_PARSE
        shift
        ;;
      -f|--file)
        cfg_setflags opts $F_CONFMAN_FILE
        cfg_set confman $2
        shift 2
        ;;
      --)
        shift
        break
        ;;
      *)
      errmsg "getopt() error"
      exit 1
      ;;
    esac
  done
}

init(){
  init_flags
  init_parseopts $@
  
  # includedir & lookup
  # Determines the include path of '.confman' file
  # It can be requested via opt
  # By default '$PWD/.confman' is inspected
  #
  local includedir=$(dirname $(cfg_get confman $PWD/.confman))
  local filename
  filename=$(confman_lookup $includedir)
  if [ $? -eq 1 ]; then
    errmsg "Unable to find .confman file in '$includedir'"
    exit 1
  fi
  
  #
  # Save current .confman filename
  cfg_set confman $filename
  echo "Using $(cfg_get confman)"
  dispatch
}

dispatch(){
  
  buf=$(confman_parse)
  echo "$buf"
  exit 1
  if cfg_testflags opts $F_CONFIG_PRINT; then
    echo "you have requested to print the config only"
    exit
  fi

  errmsg "no route to dispatch"
  help 1
}

dispatch_snapshot(){
  echo "dispatcher for snapshot section"
  exit
}

init $@
