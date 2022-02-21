
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

snapshot_printf(){
  local buf a i fmt ofmt
  local destdir

  fmt="$1"
  while read buf; do
    IFS="$CONFMAN_FS"
    read -r -a a <<< "$buf"
    ofmt="$fmt"
    # match pattern
    i=$(expr index "$ofmt" "%p")
    if [ $i -ne -1 ]; then
      # replace pattern
      destdir="$(snapshot_destdir "${a[1]}")"
      filename="$(snapshot_filename "${a[1]}" "${a[0]}" "${a[2]}")"
      filename="${destdir}/${filename}--${a[3]}.tar.gz"
      ofmt="$(printf "%s" "$ofmt" | sed "s|%p|$filename|")"
    fi
    i=$(expr index "$ofmt" "%n")
    if [ $i -ne -1 ]; then
      ofmt="$(printf "%s" "$ofmt" | sed "s/%n/${a[0]}/")"
    fi
    printf "%b" "$ofmt"
  done <<< "$(</dev/stdin)"

  return 0 
}

