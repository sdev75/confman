snapshot_remove(){
  local repodir name tag ns

  repodir="$1" ns="$2" name="$3" tag="$4"

  echo "repo: $repodir ns $ns name $name tag $tag"
  local buf files
  files="$(snapshot_list_ "$repodir" "$ns" "$name" "$tag")"

  if [ -z "$files" ]; then
    echo "OK. Nothing to remove."
    return 0
  fi
 
  while read buf; do
    IFS="$CONFMAN_FS"
    read -r name_ ns_ tag_ hash_ <<< "$buf"
    
    filename="$(snapshot_filename "$ns_" "$name_" "$tag_")"
    cmd="rm '$repodir/$ns_/$filename--$hash_.tar.gz'"
    if cfg_testflags "opts" "$F_DRYRUN"; then
      printf "Dryrun: %s\n" "$cmd"
      continue
    fi

    err=$(eval "$cmd 2>&1"); errno=$?
    if [ $errno -ne 0 ]; then
      errmsg "Could not remove snapshot: $err Errno: $errno"
      return $errno
    fi

    printf "%s\n" "OK Deleted: '$filename--$hash_.tar.gz'"
  done <<< "${files[@]}"

  return 0
}
