confman_lookup_(){
  if test -e "$1/.confman"; then
    echo "$1/.confman"
    return 0
  fi

  # traverse path until .confman is found
  if [ "/" = "$1" ]; then
    return 1
  fi
  confman_lookup_ $(dirname "$1")
}

confman_lookup(){
  local includedir filename
  includedir="$1"
  filename=$(confman_lookup_ "$includedir")
  if [ $? -eq 1 ]; then
    return 1
  fi

  echo $filename 
  return 0
}

# int confman_parse (filename)
# Parse configuration and output processed data
confman_parse_(){
  local script buf res
  script=('
#include confman.awk
  ')

  buf=$(awk -v fs=$"\x1d" -v rs=$"\x1e" "$script" "$1")
  res=$?
  echo -ne "$buf"
  return $(( $res ))
}

confman_parse(){
  local buf IFS
  buf=$(confman_parse_ "$1")
  if [ $? -ne 0 ]; then
    return 1
  fi

  echo -ne "$buf"
  return 0
}

confman_print(){
  local buf name action filename flags
  buf=$(echo -ne $1)
 # echo -ne $buf | hexdump -C; exit 
  IFS=$'\x1e'
  rs=$'\x1e'
  fs=$'\x1d'
  
  echo -e "NAME${fs}ACTION${fs}FILENAME${fs}FLAGS" 
  read -a records <<< $buf
  for record in "${records[@]}"; do
    IFS=$'\x1d'
    read -r -a fields <<< $(echo -ne "$record" | xargs)
    if [ ${#fields[@]} -eq 1 ]; then
      name="${fields[0]}"
      continue
    fi

    action="${fields[0]}"
    filename="${fields[1]}"
    flags=$(( "${fields[2]}" ))
    echo -e "$name${fs}$action${fs}$filename${fs}$flags"

  done
  exit

  for record in "$buf"; do
    IFS=$'\x1d'
    read -r -a fields <<< "$record"
    continue    
#if [ ${#fields[@]} -eq 1 ]; then
    #  name="${fields[0]}"
    #  continue
    #fi
    
  done

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

