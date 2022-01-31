
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
  local namespace name tag buf

  namespace="$1"
  name="$2"
  tag="$3"

  buf=$(confman_parse $(cfg_get "confman"))
  if [ $? -ne 0 ]; then
    errmsg "An error has occurred while parsing the configuration file"
    return $?
  fi

  echo "snapshot create called for <ns:$namespace> <name:$name> <tag:$tag>"
  exit  
  local cachedir dstdir
  cachedir=$(cfg_get "cachedir")
  dstdir="$cachedir/$namespace"

  if [ -z "$name" ]; then
    errmsg "You must specify a name"
    return 1
  fi

  local fn
  fn=$(confman_getfunction "$name")
  if [ $? -ne 0 ]; then
    errmsg "$name does not exist"
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
  buf=$(ls -apt "$1" | grep -v '/$' | grep ".tar\|.tar.gz$" \
    | awk \
     -v current_dir="$1" \
     -v ofs="\x1d" \
     "$(snapshot_fmt_ls)" \
    | column -s $'\x1d' -t)
  echo "$buf"
}

snapshot_ls(){
  local namespace group tag cachedir

  namespace="$1"
  cachedir=$(cfg_get "cachedir")

  #echo "$(ls -laA "$cachedir/$namespace")"

  echo "$(snapshot_ls_ "$cachedir/$namespace")"


}
