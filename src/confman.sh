confman_lookup_(){
  if test -e "$1/.confman"; then
    echo "$1/.confman"
    return 0
  fi

  # traverse path until .confman is found
  # temporarily disabled
  return 1
  if [ "/" = "$1" ]; then
    return 1
  fi
  confman_lookup_ $(dirname "$1")
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

# int confman_parse (filename)
# Parse configuration and output processed data
confman_parse_(){
  local scriopt buf res
  script=('
#include confman.awk
  ')

  buf=$(awk "$script" "$1")
  res=$?
  echo "$buf"
  return $(( $res ))
}

confman_parse(){
  local buf IFS
  buf=$(confman_parse_ "$1")
  if [ $? -ne 0 ]; then
    return 1
  fi

  eval "$buf"
  echo "$buf"


  
}

CONFMAN_FUNC_PREFIX='__cm_'

# int getfunction(name)
confman_getfunction(){
  local name
  name=$1
  while read line; do
    if [ "$line" = "${CONFMAN_FUNC_PREFIX}${name}" ]; then
      echo $line
      return 0
    fi
  done <<< $(confman_getfunctions "$name")
  return 1
}

confman_getfunctions(){
  echo "$(declare -F | grep -o "${CONFMAN_FUNC_PREFIX}${1}"'.*')"
}

