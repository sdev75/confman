
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
    mkdir -p "$1"
  fi
}

snapshot_create(){
  local namespace="$1" group="$2" tag="$3"
  
  echo "snapshot create called for <ns:$namespace> <group:$group> <tag:$tag>"
  #return 0

  #snapshot_initdir $cachedir/$snapshotid

  #export CACHEDIR=$cachedir
  #export SRCDIR=$(pwd)
  #export SNAPSHOTID=$snapshotid
  #__cm_vim
}
