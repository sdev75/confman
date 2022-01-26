#!/usr/bin/env sh

#include misc.sh
#include cfg.sh

# Set default cachedir 
# default value to ~/.cache/confman
# Its possible to pass the value by ENV using CACHEDIR=. confman
if [ -z ${CACHEDIR+x} ]; then
  CACHEDIR=$HOME/.cache/confman
fi

cache_init(){
  # CacheDir must exists to operate correctly
  if [ ! -d $CACHEDIR ]; then
    read -rep "$CACHEDIR does not exist. Would you like to create it? (y/n)" -n 1
    if echo $REPLY | grep -Eq '[yY]'; then
      mkdir -p $CACHEDIR
    else
     errmsg "$CACHEDIR is required to use this program" 
     exit 1
    fi
  fi

  # Ge the absolute path and compare it with current working directory
  CACHEDIR=$(realpath "$CACHEDIR")
  if [ "$CACHEDIR" = "$(pwd)" ]; then
    errmsg "In sourcing disabled"
    exit 1
  fi
}

snapshot_id(){
  #echo $(date +%Y-%d-%b) | tr '[:upper:]' '[:lower:]'
  echo $(date +%s)
}

checksum(){
  local res=$(sha256sum "$1" | awk 'print $1}')
  return $res
}

archive(){
  local filename=$1
  shift
  local files=$@

  echo "filename is $filename"
  echo "files are $files"
}

#gpg(){}

parseopts(){
  local shortargs longargs opts
}

parse(){
  if [ ! -f .confman ]; then
    errmsg ".confman not found in '$(pwd)'."
    exit 1
  fi
  script=('
    function getfilename (groupid){
      return "${CACHEDIR}/${SNAPSHOTID}/" groupid ".tar"
    }
    function gettarcmd (src, dst){
      return "tar -v --append --file=\"" dst "\" \""  src "\""
    }
    function getgzipcmd (filename){
      return "gzip -9 \"" filename "\""
    }
    BEGIN {
      group_idx = 0
      group_cmds = 0
    }
    {
      if ($0 ~ /[[:alnum:]]+ *{/) { 
        #  print "gzip -9 " filename

        match($0,/^([a-z]+).*/,m)
        
        groupid = m[1]
        groups[groupid] = 0
        gensub(/^([a-z]+).*/,"__\\1(){", "g")
      
      } else {
        if ($1 == "add") {
          idx = groups[groupid]
          groupcmds[groupid][idx] = gettarcmd($2,getfilename(groupid))
          groups[groupid] += 1
        }
      }

    }
    END {
      print "#!/usr/bin/env sh"
      print "# Generated by Confman. Link: github.com/sdev75/confman"
      
      # Add confman file automatically
      groupcmds["confman"][0] = gettarcmd(".confman", getfilename("confman"))
      
      # Iterate through all the groups and build data
      for (groupid in groupcmds){
        print "__cm_" groupid "(){"
        for (i=0; i < length(groupcmds[groupid]); i++){
          print  groupcmds[groupid][i]
        }
        #print getgzipcmd(getfilename(groupid))
        print "}"
      }
    }
  ')

  buf=$(awk "$script" .confman)
  echo "$buf"
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

init(){
  cfg_setflags opts 0
}
init $@u
