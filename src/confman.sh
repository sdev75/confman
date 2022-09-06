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
  confman_resolve_ "$(dirname "$1")"
}

confman_resolve(){
  local includedir filename

  if [ -n "$1" ]; then
    # use requested includedir
    includedir="$1"
  else
    # attempt to get file from within directory
    includedir=$(dirname "$(cfg_get "confman" "$PWD/.confman")")
  fi
  
  filename=$(confman_resolve_ "$includedir")
  if [ $? -eq 1 ]; then
    return 1
  fi

  # Save current .confman filename
  cfg_set "confman" "$filename"
  return 0
}

# int confman_parse (filename)
# Parse configuration and output processed data
confman_parse_(){
  local script buf res
  script=('
#include confman.awk
  ')
  
  buf=$(awk -v fs="$CONFMAN_FS" -v rs="$CONFMAN_RS" "${script[0]}" "$1")
  res=$?
  printf "%s" "$buf" | xxd -p
  return $(( res ))
}

confman_parse(){
  local buf IFS

  buf=$(confman_parse_ "$1")
  if [ $? -ne 0 ]; then
    return 1
  fi

  printf "%s" "$buf"
  return 0
}

# We use x1e and x1d as record and field separator respectively
CONFMAN_RS=$'\x1e'
CONFMAN_FS=$'\x1f'

confman_print(){
  local buf records fields
  local name action filename flags
  local rs fs
  
  rs=$CONFMAN_RS
  fs=$CONFMAN_FS
  
  buf="$(printf "%s" "$1" | xxd -r -p)"

  # Print labels
  printf "%s\n" "NAME${fs}ACTION${fs}FILENAME${fs}FLAGS"
 
  IFS="$rs"
  read -r -a records <<< "$buf"
  for record in "${records[@]}"; do
    IFS="$fs"
    read -r -a fields <<< "$record"
    if [ ${#fields[@]} -eq 1 ]; then
      name="${fields[0]}"
      continue
    fi

    action="${fields[0]}"
    filename="${fields[1]}"
    flags="${fields[2]}"
    printf "%s\n" "$name${fs}$action${fs}$filename${fs}$flags"
  done
}
