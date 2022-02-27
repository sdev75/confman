# extract snapshot contents
# int snapshot_extract (repodir, name, tag, namespace, what, where)
# what is the file path to extract from
# where is the path to extract `what` to
# example tar -zxf <file> -C <where> <what>
snapshot_extract(){
  local repodir name tag ns
  repodir="$1" name="$2" tag="$3" ns="$4"
  what="$5" where="$6"

  local buf files err errno
  local name_ ns_ tag_ hash_
  files="$(snapshot_list_ "$repodir" "$ns" "$name" "$tag")"
  if [ -z "$files" ]; then
    echo "OK. Nothing to extract from."
    return 0
  fi

  local tarflags tardircmd
  if cfg_testflags "opts" "$F_LIST_CONTENTS"; then
    tarflags="-ztf"
    tardircmd=""
    # Switch "where" for "what"
    if [ -n "$where" ]; then
      what="$where"
    fi
  else
    tarflags="-zxf"
    if [ -z "$where" ]; then
      errmsg "Error. Param <where> missing or invalid."
      return 1
    fi
    where="$(realpath "$where")"
    tardircmd="-C '$where'"
  fi
  
  while read buf; do
    IFS="$CONFMAN_FS"
    read -r name_ ns_ tag_ hash_ <<< "$buf"
   
    filename="$(snapshot_filename "$ns_" "$name_" "$tag_")"
    filename="$filename--${hash_}.tar.gz"

    if [ -n "$what" ]; then
      cmd="tar $tarflags '$repodir/$ns_/$filename' $tardircmd '$what'"
    else
      cmd="tar $tarflags '$repodir/$ns_/$filename' $tardircmd"
    fi

    if cfg_testflags "opts" "$F_DRYRUN"; then
      printf "Dryrun: %s\n" "$cmd"
      return 0
    fi

    err=$(eval "$cmd 2>&1") errno=$?
    if cfg_testflags "opts" "$F_LIST_CONTENTS"; then
      # err could be renamed for clarify sake
      # it contains the actual output of the tar command
      # in the case of a --contents flag set, the buffer is printed out
      echo "$err"
      return $errno 
    fi
    if [ $errno -ne 0 ]; then
      errmsg "Could not extract snapshot: $err Errno: $errno"
      return $errno
    fi
    # process only the first match
    break
  done <<< "${files[@]}"

  exit
}
