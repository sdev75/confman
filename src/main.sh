#!/usr/bin/env sh

#include misc.sh

# Set default cachedir 
# default value to ~/.cache/confman
# Its possible to pass the value by ENV using CACHEDIR=. confman
if [ -z ${CACHEDIR+x} ]; then
  CACHEDIR="~/.cache/confman"
fi

CACHEDIR=$(realpath "$CACHEDIR")
if [ "$CACHEDIR" = "$(pwd)" ]; then
  errmsg "In sourcing disabled"
  exit 1
fi
if [ ! -d $CACHEDIR ]; then
  read -rep "$CACHEDIR does not exist. Would you like to create it? (y/n)" -n 1
  if echo $REPLY | grep -Eq '[yY]'; then
    mkdir -p $CACHEDIR
  else
   errmsg "$CACHEDIR is required to use this program" 
  fi
fi

snapshot_id(){
  #echo $(date +%Y-%d-%b) | tr '[:upper:]' '[:lower:]'
  echo $(date +%s)
}

x=$(snapshot_id)
echo "x is $x"

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
  echo CACHEDIR is $CACHEDIR
  script=('
    BEGIN {
      filename = cachedir "/{groupid}_" snapshot_id ".tar.gz"
      postfix = "_" snapshot_id ".tar.gz"
    }
    {
      if (length(groupid) > 0){
        print "GZIP ALLOWED TO BE PERFORMED HERE"
      }

      if ($0 ~ /[[:alnum:]]+ *{/) { 
        match($0,/^([a-z]+).*/,m)
        groupid = m[1]
        gensub(/^([a-z]+).*/,"__\\1(){", "g")
        print "groupid is " groupid
      } else {
        print "using groupid = " groupid
        if ($1 == "add") {
          if (substr($2,length($2),1) == "/"){
            print "tar -r --file=" filename " " $2
            print "ADD COMMAND WITH DIRECTORY " $2
          }
          a = "gzip allowed"
        }
      }

    }
  ')

  awk \
    -v cachedir="$CACHEDIR" \
    -v snapshot_id="$(snapshot_id)" \
    "$script" .confman
}

parse
