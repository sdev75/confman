#!/usr/bin/env bash

#include misc.sh
#include cfg.sh
#include confman.sh
#include snapshot/snapshot.sh
#include snapshot/snapshot_create.sh
#include snapshot/snapshot_list.sh
#include snapshot/snapshot_copy.sh
#include snapshot/snapshot_remove.sh
#include snapshot/snapshot_import.sh
#include snapshot/snapshot_extract.sh
#include snapshot/snapshot_peek.sh

# Set default repodir 
# default value to ~/.cache/confman
# It's possible to pass the value by ENV using REPODIR=. confman
init_repodir(){
  local repodir

  repodir=$(realpath "$1")
  # CacheDir must exists to operate correctly
  if [ ! -d "$repodir" ]; then
    read -rep "Repository directory '$repodir' not found. Shall I create it? (y/n)" -n 1
    if echo "$REPLY" | grep -Eq '[yY]'; then
      mkdir -p "$repodir"
    else
     errmsg "'$repodir' is required to use this program" 
     exit 1
    fi
  fi

  cfg_set "repodir" "$repodir"
}

init_flags(){
  cfg_setflags "opts" 0
  readonly F_CONFMAN_FILE=$((1 << 0))
  readonly F_PARSE_ONLY=$((1 << 1))
  readonly F_DRYRUN=$((1 << 2))
  readonly F_FORCE=$((1 << 3))
  readonly F_PRINTF=$((1 << 4))
  readonly F_LIST_CONTENTS=$((1 << 5))
}

init_parseopts(){
  local shortargs longargs opts
  shortargs="hdc:t:n:f"
  longargs="help,config:,parse,repodir:,tag:,namespace:,dryrun,force"
  longargs="$longargs,printf:,contents"
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
      --repodir)
        cfg_set "repodir" "$2"
        shift 2
        ;;
      -c|--config)
        cfg_setflags "opts" $F_CONFMAN_FILE
        cfg_set "confman" "$2"
        echo $(cfg_get "confman")
        shift 2
        ;;
      -t|--tag)
        cfg_set "tag" "$2"
        shift 2
        ;;
      -n|--namespace)
        cfg_set "namespace" "$2"
        shift 2
        ;;
      -d|--dryrun)
        cfg_setflags "opts" "$F_DRYRUN"
        shift
        ;;
      -f|--force)
        cfg_setflags "opts" "$F_FORCE"
        shift
        ;;
      --printf)
        cfg_setflags "opts" "$F_PRINTF"
        cfg_set "printf" "$2"
        shift 2
        ;;
      --contents)
        cfg_setflags "opts" "$F_LIST_CONTENTS"
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
      # parse configuration data and exit
      parse)
        cfg_set "action" "parse"
        shift ${#@}
        ;;
      # create name [tag [namespace]]
      create)
        cfg_set "action" "create"
        cfg_set "namespace" "$4"
        cfg_set "tag" "$3"
        cfg_set "name" "$2"
        shift ${#@}
        ;;
      # list name [tag [namespace]]
      # list checksum
      ls | list)
        cfg_set "action" "list"
        if [ ${#@} -eq 4 ]; then
          cfg_set "tag" "$3"
          cfg_set "namespace" "$4"
          cfg_set "name" "$2"
        elif [ ${#@} -eq 3 ]; then
          cfg_set "tag" "$3"
          cfg_set "name" "$2"
        elif [ ${#@} -eq 2 ]; then
          cfg_set "name" "$2"
        fi

        shift ${#@}
        ;;

      # copy name [tag [namespace]]
      # copy checksum
      cp | copy)
        cfg_set "action" "copy"
        if [ ${#@} -eq 5 ]; then
          cfg_set "destdir" "$5"
          cfg_set "namespace" "$4"
          cfg_set "tag" "$3"
          cfg_set "name" "$2"
        elif [ ${#@} -eq 4 ]; then
          cfg_set "destdir" "$4"
          cfg_set "tag" "$3"
          cfg_set "name" "$2"
        elif [ ${#@} -eq 3 ]; then
          cfg_set "destdir" "$3"
          cfg_set "name" "$2"
        fi
        shift ${#@}
        ;;
      # remove name [tag [namespace]]
      # remove checksum
      rm | remove)
        cfg_set "action" "remove"
        cfg_set "namespace" "$4"
        cfg_set "tag" "$3"
        cfg_set "name" "$2"
        shift ${#@}
        ;;
      import)
        cfg_set "action" "import"
        if [ ${#@} -eq 5 ]; then
          cfg_set "namespace" "$5"
          cfg_set "tag" "$4"
          cfg_set "name" "$3"
        elif [ ${#@} -eq 4 ]; then
          cfg_set "tag" "$4"
          cfg_set "name" "$3"
        elif [ ${#@} -eq 3 ]; then
          cfg_set "name" "$3"
        fi

        cfg_set "filename" "$2"
        shift ${#@}
        ;;
      extract)
        cfg_set "action" "extract"
        if [ ${#@} -eq 4 ]; then
          cfg_set "what" "$4"
          cfg_set "where" "$3"
        elif [ ${#@} -eq 3 ]; then
          cfg_set "where" "$3"
        fi
        
        cfg_set "name" "$2"
        shift ${#@}
        ;;
      peek)
        cfg_set "action" "peek"
        if [ ${#@} -eq 3 ]; then
          cfg_set "what" "$3"
        fi
        
        cfg_set "name" "$2"
        shift ${#@}
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
  dispatch
}

resolve_confman(){
  # includedir & lookup
  # Determines the include path of '.confman' file
  # It can be requested via opt
  # By default '$PWD/.confman' is inspected
  #
  confman_resolve
  if [ $? -ne 0 ]; then
    errmsg "Unable to find .confman file in '$PWD' and any of its parent folders."
    return 1
  fi

  return 0
}

dispatch(){
  local buf action

  action=$(cfg_get "action" "none")
  case "$action" in
    parse)
      resolve_confman || exit $?
      parse_and_exit
      exit $?
      ;;
    list|copy|remove|import|extract|peek)
      init_repodir "$(cfg_get "repodir" "$HOME/.cache/confman")"
      dispatch_snapshot "$action"
      exit $?
      ;; 
    create)
      init_repodir "$(cfg_get "repodir" "$HOME/.cache/confman")"
      resolve_confman || exit $?
      dispatch_snapshot "$action"
      ;;
    help)
      help 0
      ;;
    *)
      help 0
      ;;
  esac
}

parse_and_exit(){
  echo "Using $(cfg_get "confman")"
  # Parse and process configuration file
  buf=$(confman_parse "$(cfg_get confman)")
  if [ $? -ne 0 ]; then
    errmsg "An error has occurred while processing '$filename'"
  fi
  confman_print "$buf" | column -s "$CONFMAN_FS" -t
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

  if [ "$1" = "copy" ]; then
    local repodir namespace name tag

    repodir=$(cfg_get "repodir")
    namespace=$(cfg_get "namespace" "default")
    name=$(cfg_get "name" "")
    tag=$(cfg_get "tag" "latest")
    destdir=$(cfg_get "destdir" "")

    snapshot_copy "$repodir" "$namespace" "$name" "$tag" "$destdir"
    return $?
  fi
  
  # list snapshots
  if [ "$1" = "list" ]; then
    local repodir namespace name tag
    repodir=$(cfg_get "repodir")
    namespace=$(cfg_get "namespace" "")
    name=$(cfg_get "name" "")
    tag=$(cfg_get "tag" "")
  
    if cfg_testflags "opts" "$F_PRINTF"; then
      local fmt="$(cfg_get "printf")"
      snapshot_list_printf "$repodir" "$namespace" "$name" "$tag" "$fmt"
      return $?
    fi

    snapshot_list "$repodir" "$namespace" "$name" "$tag" \
      | column -s "$CONFMAN_FS" -t
    return $?
  fi

  if [ "$1" = "remove" ]; then
    local repodir ns name tag
    repodir="$(cfg_get "repodir")"
    namespace=$(cfg_get "namespace" "default")
    name=$(cfg_get "name" "")
    tag=$(cfg_get "tag" "latest")
    
    snapshot_remove "$repodir" "$namespace" "$name" "$tag"
    return $?
  fi

  if [ "$1" = "import" ]; then
    local repodir ns name tag
    repodir="$(cfg_get "repodir")"
    filename="$(cfg_get "filename")"
    namespace=$(cfg_get "namespace" "")
    name=$(cfg_get "name" "")
    tag=$(cfg_get "tag" "")

    snapshot_import "$repodir" "$filename" "$namespace" "$name" "$tag"
    return $?
  fi

  if [ "$1" = "extract" ]; then
    local repodir name tag ns what where
    repodir="$(cfg_get "repodir")"
    name="$(cfg_get "name")"
    tag="$(cfg_get "tag")"
    namespace="$(cfg_get "namespace")"
    what="$(cfg_get "what")"
    where="$(cfg_get "where")"

    snapshot_extract "$repodir" "$name" "$tag" "$namespace" "$what" "$where"
    return $?
  fi

  if [ "$1" = "peek" ]; then
    local repodir name tag ns what where
    repodir="$(cfg_get "repodir")"
    name="$(cfg_get "name")"
    tag="$(cfg_get "tag")"
    namespace="$(cfg_get "namespace")"
    what="$(cfg_get "what")"

    snapshot_peek "$repodir" "$name" "$tag" "$namespace" "$what" \
      | column -s "$CONFMAN_FS" -t
    return $?
  fi
  return 0
}

init "$@"
