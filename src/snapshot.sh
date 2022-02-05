
##
# Create tarball and gzip it using attributes such as TAG
# int snapshot_create (tag)
##
snapshot_initdestdir(){
  local destdir

  destdir="$1"
  parentdir=$(dirname "$destdir")
  if [ ! -w "$parentdir" ]; then
    return 100
  fi
  if [ ! -d "$destdir" ]; then
    mkdir -p "$destdir"
    return $?
  fi
  return 0
}

snapshot_getdestdir(){
  echo "$(cfg_get "cachedir")/$1"
}

# Resolve the filename for each snapshot
# void getfilename (namespace, name, tag)
snapshot_filename(){
  local namespace name tag
  read -r namespace name tag <<< "$(echo "$1" "$2" "$3")"
  echo "${name}_${namespace}_${tag}"
}

# check if snapshot exists
# int exists(filename)
snapshot_exists(){
  if [ -f "$1" ]; then
    return 0
  fi
  
  return 1
}

snapshot_create(){
  local buf destdir errno
  local namespace name tag

  IFS=$'\x34' 
  read -r namespace name tag <<< $(printf "%b" "$1\x34$2\x34$3")

  # create <name> [options]
  if [ -z "$name" ]; then
    errmsg "Name is empty. You must specify a name"
    return 1
  fi

  buf=$(confman_parse "$(cfg_get "confman")")
  if [ $? -ne 0 ]; then
    errmsg "An error has occurred while parsing the configuration file"
    return 1
  fi

  # hex to string
  buf=$(printf "%s" "$buf" | xxd -p -r)
 
  # get destination directory for snapshots
  destdir=$(snapshot_getdestdir "$namespace")
  snapshot_initdestdir "$destdir"
  errno=$?
  if [ $errno -ne 0 ]; then
    errmsg "Unable to create destdir '$destdir'. Errno: $errno"
    return 1
  fi

  # Create snapshot backup for an existing snapshot
  # The backup file will be restored in case of an error
  local filename
  filename=$(snapshot_filename "$namespace" "$name" "$tag")

  # check if intermediary temporary file exists
  if snapshot_exists "$destdir/$filename.tar.gz.tmp" ; then
    echo "Removing intermediary temporary file: $destdir/$filename.tmp"
    rm "$destdir/$filename.tmp"
  fi
  
  ##
  # Iterate through parsed configuration data
  local records fields sbuf
  local parentdir src t1 t2

  IFS=$CONFMAN_RS
  read -r -a records <<< "$buf"
  for record in "${records[@]}"; do
    IFS=$CONFMAN_FS
    read -r -a fields <<< "$record"
    if [ ${#fields[@]} -eq 1 ]; then
      #
      # If name already matched before, this is the end
      if [ -n "$name_" ]; then
        break
      fi
      #
      # Match requested name, else keep looping
      if [ "${fields[0]}" = "$name" ]; then
        name_="$name"
        continue
      fi
    fi
    #
    # if there is no match, continue looping
    if [ -z "$name_" ]; then
      continue
    fi
    #
    # evaluate variables such as $HOME
    eval "src="${fields[1]}""
    parentdir=$(dirname "${src}")
    t1=$(printf "%s" "$src" | sed "s#$parentdir/##")
    t2="tar --append --file=\"${destdir}/${filename}.tmp\""
    sbuf="${sbuf}${t2} -C \"$parentdir\" \"$t1\"\n"
  done

  if cfg_testflags "opts" "$F_DRYRUN"; then
    echo "Dry-run requested. Commands to be executed shown below:"
    printf "%b" "$sbuf"
    return 0
  fi

  local cmd cmds res
  IFS=$'\x0a'
  read -d '' -r -a cmds <<< $"$(printf "%b" "$sbuf")"
  for cmd in "${cmds[@]}"; do
    # Eval command and store return value in `$res`
    eval "$cmd"
    res=$?
    if [ $res -ne 0 ]; then
      errmsg "Could not execute command: '$cmd' Errno: $res"
      break
    fi
  done

  if [ $res -ne 0 ]; then
    return $res
  fi


  # gzip file
  gzip -f -9 --no-name "$destdir/$filename.tmp"
  if [ $? -ne 0 ]; then
    res=$?
    errmsg "Error while executing gzip command. Errno: $res"
    echo "Removing temporary file '$destdir/$filename.tmp' ..."
    rm "$destdir/$filename.tmp"
    return $res
  fi

  # remove previous version file
  IFS=$'\n'
  read -d '' -r -a files <<< $(find "$destdir" -type f -name "$filename-*.tar.gz")
  local file
  for file in "${files[@]}"; do
    rm "$file"
    res=$?
    if [ $res -ne 0 ]; then
      errmsg "Remove failed: '$file'. Errno: $res"
      break
    fi
  done

  #if [ -f "$destdir/$filename.tar.gz" ]; then
  #  rm "$destdir/$filename.tar.gz"
  #  if [ $? -ne 0 ]; then
  #    res=$?
  #    errmsg "Cannot remove original file '$destdir/$filename.tar.gz'. Errno: $res"
  #    return $res
  #  fi
  #fi

  # perform checksum and move operation
  digest=$(sha256sum "$destdir/$filename.tmp.gz" | awk '{ print $1 }')
  mv "$destdir/$filename.tmp.gz" "$destdir/$filename-$digest.tar.gz"
  if [ $? -ne 0 ]; then
    res=$?
    errmsg "Error while mv operationg for '$destdir/$filename.tmp.gz'"
    return $res
  fi

  return $res
}

snapshot_fmt_ls(){
  local buf
  buf=('
#include fmt_ls.awk
  ')
  echo "$buf"
}

snapshot_ls_(){
  local buf
  buf=$(ls -apt "$1" | grep -v '/$' | grep ".tar\|.tar.gz$" \
    | awk \
     -v current_dir="$1" \
     -v ofs="\x1d" \
     "$(snapshot_fmt_ls)" \
    | column -s $'\x1d' -t)
  echo "$buf"
}

snapshot_ls(){
  local namespace cachedir

  namespace="$1"
  cachedir=$(cfg_get "cachedir")

  snapshot_ls_ "$cachedir/$namespace"
}
