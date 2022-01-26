
snapshot_id(){
  #echo $(date +%Y-%d-%b) | tr '[:upper:]' '[:lower:]'
  echo $(date +%s)
}

snapshot_create(){

  local snapshotid=$(snapshot_id)
  local cachedir=$CACHEDIR
  
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
