## Basic implementation of associative array with pure sh
## created by sdev75; github.com/sdev75/confman
cfg_buf_=""

##
# Example usage:
# var=$(cfg_get key1 default_value)
# if [ $? -ne 0 ]; echo "key does not exist"; fi
# 
cfg_get(){
  if [ -z "$1" ]; then
    echo -ne "$cfg_buf_"
    return 0
  fi

  local IFS=$'\035'
  for pair in $cfg_buf_; do
    local IFS=$'\036'
    read -r -a a <<< "$pair"
    if [ "${a[0]}" = "$1" ]; then
      echo -ne "${a[1]}"
      return 0
    fi
  done
  if [ -n "$2" ]; then
    echo -ne "$2"
  fi
  return 1
}

cfg_set(){
  cfg_unset "$1"
  cfg_buf_="${cfg_buf_}$(echo -ne "$1\x1e$2\x1d")"
}

cfg_unset(){
  if [ -z "$cfg_buf_" ]; then
    return 0
  fi

  cfg_buf_=$(echo -ne "$cfg_buf_" | sed "s/$1\x1e[^\x1d]*\x1d//")
  return 0
}

cfg_hexdump(){
  echo -ne "$cfg_buf_" | hexdump -C
}

# turn a flag on using a specific mask
# int setflags(flags_key, mask)
cfg_setflags(){
  local flags=$(( $(cfg_get "$1") ))
  local mask=$(( $2 ))
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
  local flags=$(( $(cfg_get "$1") ))
  local mask=$(( $2 ))
  if [ $(( flags & mask )) -gt 0 ]; then
    return 0
  fi
  return 1
}
