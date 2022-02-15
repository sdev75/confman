
# Create tarball and gzip it using attributes such as TAG
# int snapshot_create (tag)
##
snapshot_initdestdir(){
  local destdir

  destdir="$1"
  parentdir=$(dirname "$destdir")
  if [ ! -w "$parentdir" ]; then
    return 100
  fi
  if [ ! -d "$destdir" ]; then
    mkdir -p "$destdir"
    return $?
  fi
  return 0
}

snapshot_destdir(){
  echo "$(cfg_get "repodir")/$1"
}

# Resolve the filename for each snapshot
# void getfilename (namespace, name, tag)
snapshot_filename(){
  local namespace name tag
  IFS=$'\x34'
  read -r namespace name tag <<< "$(printf "%b" "${1}\x34${2}\x34${3}")"
  echo "${name}--${namespace}--${tag}"
}

