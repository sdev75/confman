# This will simply copy the file and store it in the repo directory.
# The hash is re-calculated for integrity verification
# import (repodir, filename) 
# Optional params: name, tag, namespace
snapshot_import(){
  local repodir filename
  local name tag namespace
  local basename parsed
  
  filename=$(realpath "$2")
  basename=$(basename "$filename")
  snapshot_filename_parse "$basename" parsed
  if [ $? -ne 0 ]; then
    return 1
  fi

  # repodir is assumed valid
  repodir="$1"

  # default parameter construct used for filling out overriden data
  name="${4:-${parsed[0]}}"
  tag="${5:-${parsed[2]}}"
  namespace="${3:-${parsed[1]}}"

  # checksum  not important because it will be recalculated


  local destdir destfile digest cmd opts err errno
  destdir="$(snapshot_destdir "$namespace")"
  destdir="$(realpath "$destdir")"
  
  # create destdir if not existing
  snapshot_initdestdir "$destdir"
  errno=$?
  if [ $errno -ne 0 ]; then
    errmsg "Error. Failed to create destdir '$destdir'. Errno: $errno"
    return 1
  fi

  destfile="$(snapshot_filename "$namespace" "$name" "$tag")"
  digest="$(sha256sum "$filename" | awk '{print $1}')"

  if cfg_testflags "opts" "$F_FORCE"; then
    opts=""
  else
    # do not overwrite if file already exists
    # it will likely perform without setting any errors
    opts="-n"
  fi
  
  cmd="cp $opts '$filename' '$destdir/$destfile--$digest.tar.gz'"

  if cfg_testflags "opts" "$F_DRYRUN"; then
    echo "Dry-run requested!"
    echo "  > filename '$filename'"
    echo "  > repodir '$repodir'"
    echo "  > name '$name' tag '$tag' namespace '$namespace'"
    echo "Commands to be executed shown below:"
    echo "$cmd"
    return 0
  fi

  err=$(eval "$cmd 2>&1") errno=$?
  if [ $errno -ne 0 ]; then
    errmsg "Error. Unable to import snapshot: $err Errno: $errno"
    return $errno
  fi
}
