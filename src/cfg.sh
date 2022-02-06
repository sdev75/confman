## Basic implementation of associative array with pure sh
## created by sdev75; github.com/sdev75/confman
cfg_buf_=""

##
# Example usage:
# var=$(cfg_get key1 default_value)
# if [ $? -ne 0 ]; echo "key does not exist"; fi
# 
cfg_get(){
  IFS=" "
  if [ -z "$1" ]; then
    printf "%b" "$cfg_buf_"
    return 0
  fi

  local IFS

  IFS=$'\x1e'
  read -r -a records <<< "$(printf "%b" "$cfg_buf_")"
  for record in "${records[@]}"; do
    IFS=$'\x1d'
    read -r -a fields <<< "$record"
    if [ "${fields[0]}" = "$1" ]; then
      printf "%b" "${fields[1]}"
      return 0
    fi
  done
  if [ -n "$2" ]; then
    printf "%b" "$2"
    return 2
  fi
  return 1
}

cfg_set(){
  cfg_unset "$1"
  cfg_buf_=$(printf "%b" $"${cfg_buf_}$1\x1d$2\x1e")
}

cfg_unset(){
  if [ -z "$cfg_buf_" ]; then
    return 0
  fi

  cfg_buf_=$(printf "%b" "$cfg_buf_" | sed "s/$1\x1d[^\x1e]*\x1e//")
  return 0
}

cfg_hexdump(){
  echo -ne "$cfg_buf_" | hexdump -C
}

# turn a flag on using a specific mask
# int setflags(flags_key, mask)
cfg_setflags(){
  local flags mask
  flags=$(( $(cfg_get "$1") ))
  mask=$(( $2 ))
  cfg_set "$1" $(( flags | mask ))
}

# check if a flag is set
# int testflags (flags_key, mask)
# example usage:
#
#  cfg_setflags opts 4
#  echo $(cfg_get opts)
#  if cfg_testflags opts 2; then
#    echo "flag is set"
#  else
#    echo "flag not set"
#  fi
cfg_testflags(){
  local flags mask
  flags=$(( $(cfg_get "$1") ))
  mask=$(( $2 + 0 ))
  if [ $(( flags & mask )) != 0 ]; then
    return 0
  fi
  return 1
}
