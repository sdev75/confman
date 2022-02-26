# extract snapshot contents
# int snapshot_extract (repodir, name, tag, namespace, what, where)
# what is the file path to extract from
# where is the path to extract `what` to
# example tar -zxf <file> -C <where> <what>
snapshot_extract(){
  local repodir name tag ns
  repodir="$1" name="$2" tag="$3" ns="$4"
  what="$5" where="$6"

  if [ -z "$where" ]; then
    errmsg "Error. Param <where> missing or invalid."
    return 1
  fi

  where="$(realpath "$where")"

  local buf files err errno
  local name_ ns_ tag_ hash_
  files="$(snapshot_list_ "$repodir" "$ns" "$name" "$tag")"
  if [ -z "$files" ]; then
    echo "OK. Nothing to extract from."
    return 0
  fi

  while read buf; do
    IFS="$CONFMAN_FS"
    read -r name_ ns_ tag_ hash_ <<< "$buf"
   
    filename="$(snapshot_filename "$ns_" "$name_" "$tag_")"
    filename="$filename--${hash_}.tar.gz"

    if [ -n "$what" ]; then
      cmd="tar -ztf '$repodir/$ns_/$filename' -C '$where' '$what'"
    else
      cmd="tar -ztf '$repodir/$ns_/$filename' -C '$where'"
    fi

    if cfg_testflags "opts" "$F_DRYRUN"; then
      printf "Dryrun: %s\n" "$cmd"
      return 0
    fi

    err=$(eval "$cmd 2>&1") errno=$?
    if [ $errno -ne 0 ]; then
      errmsg "Could not extract snapshot: $err Errno: $errno"
      return $errno
    fi
    # process only the first match
    break
  done <<< "${files[@]}"

  exit
}