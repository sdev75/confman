#!/usr/bin/env sh

#include misc.sh

CACHEDIR="~/.cache/confman"
if [ ! -d $CACHEDIR ]; then
  read -rep "$CACHEDIR does not exist. Would you like to create it? (y/n)" -n 1
  if echo $REPLY | grep -Eq '[yY]'; then
    mkdir -p $CACHEDIR
  else
   errmsg "$CACHEDIR is required to use this program" 
  fi
fi

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
}

parse
