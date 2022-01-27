
snapshot_id(){
  #echo $(date +%Y-%d-%b) | tr '[:upper:]' '[:lower:]'
  echo $(date +%s)
}

##
# Create tarball and gzip it using attributes such as TAG
# int snapshot_create (tag)
##
snapshot_create(){
  local cachedir snapshotid group=$1 tag=$2
  
  snapshotid=$(snapshot_id)
  cachedir=$(cfg_get cachedir)
 
  echo "snapshot create called for $group:$tag and cachedir $cachedir"
  return 0

  if [ ! -d $cachedir/$snapshotid ]; then
    mkdir -p $cachedir/$snapshotid
  fi

  buf=$(parse)
  eval "$buf"
  declare -F | grep '__cm'
  export CACHEDIR=$cachedir
  export SRCDIR=$(pwd)
  export SNAPSHOTID=$snapshotid
  __cm_vim
}
