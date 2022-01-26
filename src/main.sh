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

init_parseopts(){
  local shortargs longargs opts

  shortargs="h"
  longargs="help"
  opts=$(getopt -o $shortargs --long $longargs -- "$@")
  if (( $? -ne 0 )); then
    exit $?
  fi
  
  eval set -- "$opts"
  while true; do
    case "$1" in
      -h|--help)
        help 0
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
  cfg_setflags opts 0
  #init_parseopts $@
  
  # lookup .confman file
  local filename
  filename=$(confman_lookup $PWD)
  if [ $? -eq 1 ]; then
    echo "Unable to find configuration file. IncludeDir: '$PWD'"
    exit 1
  fi
  
  cfg_set confman $filename
  echo "Using configuration file: $(cfg_get confman)"
  echo "init called"
}

dispatch(){
  errmsg "no route to dispatch"
  help 1
}

dispatch_snapshot(){
  echo "dispatcher for snapshot section"
  exit
}

init $@u
