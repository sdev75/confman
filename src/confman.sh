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
  includedir="$1"
  filename=$(confman_resolve_ "$includedir")
  if [ $? -eq 1 ]; then
    return 1
  fi

  echo "$filename"
  return 0
}

# int confman_parse (filename)
# Parse configuration and output processed data
confman_parse_(){
  local script buf res
  script=('
#include confman.awk
  ')

  buf=$(awk -v fs=$"\x1d" -v rs=$"\x1e" "${script[0]}" "$1")
 
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
CONFMAN_FS=$'\x1d'

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

# Get actions for specific name
# The name is not the best, it might require refactoring?
# int getname(buf, name)
confman_getrecordsbyname(){
  local records fields
  local rs fs name_ name
  
  rs=$CONFMAN_RS
  fs=$CONFMAN_FS
  name_="$2"

  local buf
  buf=$(printf "%s" "$1" | xxd -p -r)
  printf "%s" "$buf" | hexdump -C
  exit
  records=($(confman_read_records "$(echo -ne $1)"))
  for record in "${records[@]}"; do
    echo "record found: $record" 
    fields=($(confman_read_fields "$record"))

    # skip all fields with count > 1
    # Format is as follows:
    # <name>{RS}
    # <action>{FS}<foo>{FS}<bar>{RS}
    # <action>{FS}<foo>{FS}<bar>{RS}
    # When a record has only 1 field, it defines an idetifier
    # for the fields that follow its declaration
    if [ ${#fields[@]} -eq 1 ]; then
      if [ -n "$name" ]; then
        # already found, break
        break
      fi
      if [ "${fields[0]}" = "$name_" ]; then
        name="${fields[0]}"
      fi
    fi

    # Skip to next record if the first field is not matching with $name
    if [ -z "$name" ]; then
      continue
    fi
    
    action="${fields[0]}"
    filename="${fields[1]}"
    flags=$(( "${fields[2]}" ))
    echo -ne "$action${fs}$filename${fs}$flags${rs}"
  done
}
