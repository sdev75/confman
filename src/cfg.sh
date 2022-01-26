## Basic implementation of associative array with pure sh
## created by sdev75; github.com/sdev75/confman
cfg_buf_=""

##
# Example usage:
# var=$(cfg_get key1)
# if [ $? -ne 0 ]; echo "key does not exist"; fi
# 
cfg_get(){
  if [ -z $1 ]; then
    echo $cfg_buf_
    return 0
  fi

  local IFS=$'\035'
  for pair in $cfg_buf_; do
    local IFS=$'\036'
    read -r -a a <<< "$pair"
    if [ "${a[0]}" = "$1" ]; then
      echo ${a[1]}
      return 0
    fi
  done
  return 1
}

cfg_set(){
  cfg_unset $1
  local buf="$1\x1e$2\x1d"
  cfg_buf_+=$(echo -e $buf)
}

cfg_unset(){
  if [ -z $cfg_buf_ ]; then
    return 0
  fi

  cfg_buf_=$(echo -e $cfg_buf_ | sed "s/$1\x1e[^\x1d]*\x1d//")
  return 0
}

cfg_hexdump(){
  echo -e $cfg_buf_ | hexdump -C
