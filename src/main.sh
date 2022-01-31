#!/usr/bin/env sh

#include misc.sh
#include cfg.sh
#include confman.sh
#include snapshot.sh

# Set default cachedir 
# default value to ~/.cache/confman
# Its possible to pass the value by ENV using CACHEDIR=. confman
init_cachedir(){
  local cachedir=$1

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
        cfg_set "action" "create"
        if [ ! -z "$2" ]; then
          cfg_set "name" "$2"
          #if [ $(expr index "$2" ":") ]; then
          #  local IFS=':'
          #  read -r -a pair <<< "$2"
          #  namespace=${pair[0]}
          #  group=${pair[1]}
          #  cfg_set "namespace" "${pair[0]}"
          #  cfg_set "group" "${pair[1]}"
          #else
          #  namespace="default"
          #  group=$2
          #fi
          shift 2
          break
        fi
        shift
        ;;
      ls)
        cfg_set "action" "ls"
        if [ ! -z "$2" ]; then
          cfg_set "name" "$2"
          shift 2
          break
        fi
        
        shift
        ;;
      *)
        shift
        ;;
    esac
    if [ -z "$@" ]; then break; fi
  done
}

init(){
  init_flags
  init_parseopts "$@"
  init_cachedir $(cfg_get cachedir $HOME/.cache/confman)
  
  # includedir & lookup
  # Determines the include path of '.confman' file
  # It can be requested via opt
  # By default '$PWD/.confman' is inspected
  #
  local includedir filename
  includedir=$(dirname $(cfg_get "confman" "$PWD/.confman"))
  filename=$(confman_lookup "$includedir")
  if [ $? -eq 1 ]; then
    errmsg "Unable to find .confman file in '$includedir'"
    exit 1
  fi
  
  #
  # Save current .confman filename
  cfg_set "confman" "$filename"
  echo "Using $(cfg_get confman)"
  dispatch
}

dispatch(){
  local buf
  # Print processed conf without proceeding further
  if cfg_testflags "opts" "$F_PARSE_ONLY"; then
    # Parse and process configuration file
    buf=$(confman_parse $(cfg_get confman))
    if [ $? -ne 0 ]; then
      errmsg "An error has occurred while processing '$filename'"
    fi
    #echo "Printing parsed configuration formatted raw data below:"
    #echo "$buf"
    #echo "Formatted output:"
    confman_print "$buf" | column -s $'\x1d' -t
    exit
  fi

  action=$(cfg_get "action" "none")
  case "$action" in
    create)
      dispatch_snapshot "$action"
      ;;
    ls)
      dispatch_snapshot "$action"
      ;;
    *)
      errmsg "No route available for action '$action'"
      ;;
  esac
}

dispatch_snapshot(){
  
  # create snapshot
  if [ "$1" = "create" ]; then
    local namespace name tag
    namespace=$(cfg_get "namespace" "default")
    group=$(cfg_get "name" "")
    tag=$(cfg_get "tag" "latest")

    confman_parse_and_eval $(cfg_get "confman")
    if [ $? -ne 0 ]; then
      errmsg "An error has occurred while parsing the configuration file"
      return $?
    fi

    snapshot_create "$namespace" "$name" "$tag"
    return $?
  fi

  # list snapshots
  if [ "$1" = "ls" ]; then
    local namespace name tag
    namespace=$(cfg_get "namespace" "default")
    group=$(cfg_get "name" "")
    tag=$(cfg_get "tag" "latest")

    snapshot_ls "$namespace" "$name" "$tag"
    return $?
  fi

  return 0
}

init "$@"
