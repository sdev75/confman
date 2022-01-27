#!/usr/bin/env sh

#include misc.sh
#include cfg.sh
#include confman.sh
#include snapshot.sh

# Set default cachedir 
# default value to ~/.cache/confman
# Its possible to pass the value by ENV using CACHEDIR=. confman
init_cachedir(){
  local cachedir=$(cfg_get cachedir $HOME/.cache/confman)

  # CacheDir must exists to operate correctly
  if [ ! -d $cachedir ]; then
    read -rep "$cachedir not found. Shall I create it? (y/n)" -n 1
    if echo $REPLY | grep -Eq '[yY]'; then
      mkdir -p $cachedir
    else
     errmsg "$cachedir is required to use this program" 
     exit 1
    fi
  fi

  cachedir=$(realpath $cachedir)
  cfg_set cachedir $cachedir
}

checksum(){
  local res=$(sha256sum "$1" | awk 'print $1}')
  return $res
}

init_flags(){
  cfg_setflags opts 0
  readonly F_CONFMAN_FILE=$((1 << 0))
  readonly F_PARSE_ONLY=$((2 << 0))
}

init_parseopts(){
  local shortargs longargs opts
  shortargs="hf:t:"
  longargs="help,file:,parse,cachedir:tag:"
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
        cfg_setflags opts $F_PARSE_ONLY
        shift
        ;;
      --cachedir)
        cfg_set cachedir $2
        shift 2
        ;;
      -f|--file)
        cfg_setflags opts $F_CONFMAN_FILE
        cfg_set confman $2
        shift 2
        ;;
      -t|--tag)
        cfg_set tag $2
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

  # parse arguments
  while true; do
    case "$1" in
      create)
        cfg_set action create
        if [ ! -z $2 ]; then
          cfg_set group $2
          shift 2
          break
        fi
        shift
        ;;
      *)
        shift
        ;;
    esac
    if [ -z $@ ]; then break; fi
  done
  echo $opts
  echo $@
}

init(){
  init_flags
  init_parseopts $@
  init_cachedir
  
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
  local buf
  local filename=$(cfg_get confman)
  
  # Parse and process configuration file
  buf=$(confman_process $filename)
  if [ $? -ne 0 ]; then
    errmsg "An error has occurred while processing '$filename'"
  fi
 
  # Print processed conf without proceeding further
  if cfg_testflags opts $F_PARSE_ONLY; then
    echo "$buf"
    exit
  fi

  local action=$(cfg_get action none)
  case "$action" in
    create)
      dispatch_snapshot
      break
      ;;
    *)
      errmsg "No route for the action requested"
      exit 1
      ;;
  esac
}

dispatch_snapshot(){
  local tag=$(cfg_get tag latest)
  local group=$(cfg_get group *)
  snapshot_create $group $tag
  exit $?
}

init $@
