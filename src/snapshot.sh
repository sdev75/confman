
snapshot_id(){
  #echo $(date +%Y-%d-%b) | tr '[:upper:]' '[:lower:]'
  echo $(date +%s)
}

##
# Create tarball and gzip it using attributes such as TAG
# int snapshot_create (tag)
##
snapshot_initdir(){
  if [ ! -d "$1" ]; then
    echo "Creating snapshot cache directory: $1"
    mkdir -p "$1"
  fi
}

snapshot_create(){
  local namespace group tag

  namespace="$1"
  group="$2"
  tag="$3"

  echo "snapshot create called for <ns:$namespace> <group:$group> <tag:$tag>"
  
  local cachedir dstdir
  cachedir=$(cfg_get "cachedir")
  dstdir="$cachedir/$namespace"

  if [ -z "$group" ]; then
    errmsg "You must specify a group"
    return 1
  fi

  local fn
  fn=$(confman_getfunction "$group")
  if [ $? -ne 0 ]; then
    errmsg "$group does not exist"
    return 1
  fi

  # Create destination directory if this doesnt exist
  # pattern: <cachedir>/<namespace>
  snapshot_initdir "$dstdir"

  # Set the Confman destination directory
  # This variable is used by the __cm_<name>() function
  CM_DSTDIR="$dstdir"
  eval "$fn"
#snapshot_initdir "$dstdir"


  #export CACHEDIR=$cachedir
  #export SRCDIR=$(pwd)
  #export SNAPSHOTID=$snapshotid
  #__cm_vim
}

snapshot_fmt_ls(){
  local buf
  buf=('
#include fmt_ls.awk
  ')
  echo "$buf"
}

snapshot_ls_(){
  local buf
  buf=$(ls -ap "$1" | grep -v '/$' | grep ".tar$" \
    | awk -v current_dir="$1" "$(snapshot_fmt_ls)" \
    | column -s ":" -t)
  echo "$buf"
}

snapshot_ls(){
  local namespace group tag cachedir

  namespace="$1"
  cachedir=$(cfg_get "cachedir")

  #echo "$(ls -laA "$cachedir/$namespace")"

  echo "$(snapshot_ls_ "$cachedir/$namespace")"


}
