snapshot_copy(){
  local fromdir destdir
  local ns name tag

  fromdir="$1"
  ns="$2"
  name="$3"
  tag="$4"
  destdir="$5"
 
  # Get matched files using filtering
  local filename
  files="$(snapshot_list_ "$fromdir" "$ns" "$name" "$tag")"
  if [ -z "$files" ]; then
    return 2
  fi
  
  IFS="$CONFMAN_FS"
  local name_ ns_ tag_ checksum_
  local filename cmd err errno digest
  while read -r buf; do
    read -r name_ ns_ tag_ checksum_  <<< "$buf"
    filename=$(snapshot_filename "$ns_" "$name_" "$tag_")
   
    cmd="cp \"$fromdir/$ns_/$filename--$checksum_.tar.gz\""
    cmd="$cmd \"$destdir/$filename--$checksum_.tar.gz\""

    if cfg_testflags "opts" "$F_DRYRUN"; then
      printf "%s\n" "$cmd"
      continue
    fi
  
    if ! cfg_testflags "opts" "$F_FORCE"; then
      if [ -f "$destdir/$filename--$checksum_.tar.gz" ]; then
        errmsg "File exists: $destdir/$filename--$checksum_.tar.gz"
        errmsg "Use --force flag to overwrite existing file"
        return 1
      fi
    fi

    err=$(eval "$cmd 2>&1"); errno=$?
    if [ $errno -ne 0 ]; then
      errmsg "Error while copying snapshot: $err Errno: $errno"
      return $errno
    fi

    # Verify checksum for integrity
    digest=$(sha256sum "$destdir/$filename--$checksum_.tar.gz" | awk '{ print $1 }')
    if [ "$checksum_" != "$digest" ]; then
      errmsg "Digest mismatch. File integrity is comprimised."
      errmsg "File: '$destdir/$filename--$checksum.tar.gz'"
      return 1
    fi

    printf "%s\n" "OK: $destdir/$filename--$checksum_.tar.gz"
    
  done <<< "$files"
  return 0
}
