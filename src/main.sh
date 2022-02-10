#!/usr/bin/env sh

#include misc.sh
#include cfg.sh
#include confman.sh
#include snapshot.sh

# Set default cachedir 
# default value to ~/.cache/confman
# Its possible to pass the value by ENV using CACHEDIR=. confman
init_cachedir(){
  local cachedir

  cachedir="$1"
  # CacheDir must exists to operate correctly
  if [ ! -d "$cachedir" ]; then
    read -rep "$cachedir not found. Shall I create it? (y/n)" -n 1
    if echo "$REPLY" | grep -Eq '[yY]'; then
      mkdir -p "$cachedir"
    else
     errmsg "$cachedir is required to use this program" 
     exit 1
    fi
  fi

  cachedir=$(realpath "$cachedir")
  cfg_set "cachedir" "$cachedir"
}

init_flags(){
  cfg_setflags "opts" 0
  readonly F_CONFMAN_FILE=$((1 << 0))
  readonly F_PARSE_ONLY=$((2 << 0))
  readonly F_DRYRUN=$((4 << 0))
}

init_parseopts(){
  local shortargs longargs opts
  shortargs="hf:t:"
  longargs="help,file:,parse,cachedir:,tag:,dryrun"
  opts=$(getopt -o $shortargs --long $longargs -- "$@")
  if [ $? -ne 0 ]; then
    exit $?
  fi

  eval set -- "$opts"
  while true; do
    case "$1" in
      -h|--help)
        help 0
        ;;
      --parse)
        cfg_setflags "opts" $F_PARSE_ONLY
        shift
        ;;
      --cachedir)
        cfg_set "cachedir" "$2"
        shift 2
        ;;
      -f|--file)
        cfg_setflags opts $F_CONFMAN_FILE
        cfg_set "confman" "$2"
        shift 2
        ;;
      -t|--tag)
        cfg_set "tag" "$2"
        shift 2
        ;;
      --dryrun)
        cfg_set "opts" "$F_DRYRUN"
        shift
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
      mk |  create)
        cfg_set "action" "create"
        
        # format:
        #   create <name> [<namespace>] [<tag>]
        #
        if [ ${#@} -eq 4 ]; then
          cfg_set "tag" "$4"
          cfg_set "namespace" "$3"
          cfg_set "name" "$2"
          shift 4
          break
        fi
        if [ ${#@} -eq 3 ]; then
          cfg_set "namespace" "$3"
          cfg_set "name" "$2"
          shift 3
          break
        fi

        if [ ${#@} -eq 2 ]; then
          cfg_set "name" "$2"
          shift 2
          break
        fi

        shift
        ;;
      ls | list)
        cfg_set "action" "list"
        
        # format:
        #   ls [name [tag [namespace]]]
        #
        if [ ${#@} -eq 4 ]; then
          cfg_set "tag" "$3"
          cfg_set "namespace" "$4"
          cfg_set "name" "$2"
          shift 4

        elif [ ${#@} -eq 3 ]; then
          cfg_set "tag" "$3"
          cfg_set "name" "$2"
          shift 3
        
        elif [ ${#@} -eq 2 ]; then
          cfg_set "name" "$2"
          shift 2
          
        else
          shift
        fi
        ;;
      *)
        shift
        ;;
    esac
    if [ -z "$1" ]; then break; fi
  done
}

init(){
  init_flags
  init_parseopts "$@"
  init_cachedir "$(cfg_get "cachedir" "$HOME/.cache/confman")"
  
  # includedir & lookup
  # Determines the include path of '.confman' file
  # It can be requested via opt
  # By default '$PWD/.confman' is inspected
  #
  local includedir filename
  includedir=$(dirname "$(cfg_get "confman" "$PWD/.confman")")
  filename=$(confman_resolve "$includedir")
  if [ $? -ne 0 ]; then
    errmsg "Unable to find .confman file in '$includedir'"
    exit 1
  fi
  
  #
  # Save current .confman filename
  cfg_set "confman" "$filename"
  dispatch
}

dispatch(){
  local buf action
  # Print processed conf without proceeding further
  if cfg_testflags "opts" "$F_PARSE_ONLY"; then
    echo "Using $(cfg_get confman)"
    # Parse and process configuration file
    buf=$(confman_parse "$(cfg_get confman)")
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
    "list")
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
    name=$(cfg_get "name" "")
    tag=$(cfg_get "tag" "latest")
    
    snapshot_create "$namespace" "$name" "$tag"
    return $?
  fi
  
  # list snapshots
  if [ "$1" = "list" ]; then
    local namespace name tag
    cachedir=$(cfg_get "cachedir")
    namespace=$(cfg_get "namespace" "")
    name=$(cfg_get "name" "")
    tag=$(cfg_get "tag" "")
    
    snapshot_ls "$cachedir" "$namespace" "$name" "$tag" \
      | column -s "$CONFMAN_FS" -t
    return $?
  fi

  return 0
}

init "$@"
