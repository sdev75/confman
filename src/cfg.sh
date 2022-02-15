cfg_get(){
  local cfgvar_
  cfgvar_="cfgvar__$1"
  echo "${!cfgvar_:=$2}"
}
cfg_set(){
  if [ -z "$2" ]; then 
    return 1
  fi
  local cfgvar_
  cfgvar_="cfgvar__$1"
  eval "cfgvar__${1}=\"${2}\""
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
