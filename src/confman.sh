confman_lookup_(){
  if test -e "$1/.confman"; then
    echo "$1/.confman"
    return 0
  fi
  if [ "/" = "$1" ]; then
    return 1
  fi
  confman_lookup $(dirname "$1")
}

confman_lookup(){
  local filename
  local includedir=$1
  filename=$(confman_lookup_ $includedir)
  if [ $? -eq 1 ]; then
    return 1
  fi

  echo $filename 
  return 0
}

confman_parse(){
  script=('
#include confman.awk 
  ')

  buf=$(awk "$script" .confman)
  echo "$buf"
}

