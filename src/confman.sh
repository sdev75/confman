# Recursive command
# Will traverse path to the root until a .confman is found
confman_resolve_(){
  if test -e "$1/.confman"; then
    echo "$1/.confman"
    return 0
  fi

  # Stop at root node '/'
  if [ "/" = "$1" ]; then
    return 1
  fi
  confman_resolve_ $(dirname "$1")
}

confman_resolve(){
  local includedir filename
  includedir="$1"
  filename=$(confman_resolve_ "$includedir")
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


confman_read_records(){
  local IFS records
  IFS=$'\x1e'
  read -a records <<< $(echo -ne "$1")
  echo -ne "${records[@]}"
}

confman_read_fields(){
  local IFS fields
  IFS=$'\x1d'
  read -a fields <<< $(echo -ne "$1")
  echo -ne "${fields[@]}"
}

confman_print(){
  local records fields
  local name action filename flags

  # We use x1e and x1d as record and field separator respectively
  rs=$'\x1e'
  fs=$'\x1d'

  # Print labels
  echo -e "NAME${fs}ACTION${fs}FILENAME${fs}FLAGS" 
  
  # Print formatted data using records and fields
  records=$(confman_read_records "$(echo -ne $1)")
  for record in ${records[@]}; do
    
    fields=($(confman_read_fields "$record"))
    if [ ${#fields[@]} -eq 1 ]; then
      name="${fields[0]}"
      continue
    fi

    action="${fields[0]}"
    filename="${fields[1]}"
    flags=$(( "${fields[2]}" ))
    echo -e "$name${fs}$action${fs}$filename${fs}$flags"
  done

  # buf should be echoed using -e and -n flags
  #buf=$(echo -ne $1)
  
}
