# peek snapshot contents
# int snapshot_peek (repodir, name, tag, namespace, what)
# what is used to filter out results
# example tar -ztf file [what]
snapshot_peek_(){
  local repodir name tag ns
  repodir="$1" name="$2" tag="$3" ns="$4" what="$5"

  local buf files err errno
  local name_ ns_ tag_ hash_
  files="$(snapshot_list_ "$repodir" "$ns" "$name" "$tag")"
  if [ -z "$files" ]; then
    echo "OK. No files match."
    return 0
  fi

  while read buf; do
    IFS="$CONFMAN_FS"
    read -r name_ ns_ tag_ hash_ <<< "$buf"
   
    filename="$(snapshot_filename "$ns_" "$name_" "$tag_")"
    filename="$filename--${hash_}.tar.gz"

    cmd="tar -xf '$repodir/$ns_/$filename' --to-command='"
    cmd="${cmd}sha256sum | sed \"s,  -,${CONFMAN_FS}\$TAR_FILENAME,\"'"

    if [ -n "$what" ]; then
      cmd="${cmd} '$what'"
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
    echo "$err"
    return $errno 
    # process only the first match
    break
  done <<< "${files[@]}"
}

snapshot_peek(){
  local repodir name tag ns
  repodir="$1" name="$2" tag="$3" ns="$4" what="$5"
  
  local fs rs
  fs="$CONFMAN_FS" rs=$'\n'
  printf "%s${fs}%s${rs}" "CHECKSUM" "FILENAME"

  snapshot_peek_ "$repodir" "$name" "$tag" "$ns" "$what"
}
