
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

snapshot_destdir(){
  echo "$(cfg_get "cachedir")/$1"
}

# Resolve the filename for each snapshot
# void getfilename (namespace, name, tag)
snapshot_filename(){
  local namespace name tag
  IFS=$'\x34'
  read -r namespace name tag <<< "$(printf "%b" "${1}\x34${2}\x34${3}")"
  echo "${name}--${namespace}--${tag}"
}

# check if snapshot exists
# int exists(filename)
snapshot_exists(){
  if [ -f "$1" ]; then
    return 0
  fi
  
  return 1
}

snapshot_buildcmds(){
  local buf name

  name="$1"
  buf=$(confman_parse "$(cfg_get "confman")")
  if [ $? -ne 0 ]; then
    return $?
  fi

  # hex to string
  buf=$(printf "%s" "$buf" | xxd -p -r)
 
  ##
  # Iterate through parsed configuration data
  local records fields sbuf
  local parentdir src t1 t2

  local IFS
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
    eval "src=\"${fields[1]}\""
    parentdir=$(dirname "${src}")
    t1=$(printf "%s" "$src" | sed "s#$parentdir/##")
    t2="tar --append --file=\"{{filename}}\""
    sbuf="${sbuf}${t2} -C \"$parentdir\" \"$t1\"\n"
  done
  
  if [ -z "$name_" ]; then
    return 100
  fi

  printf "%b" "$sbuf"
  return 0
}

snapshot_create(){
  local buf destdir errno
  local namespace name tag

  local IFS=$'\x34'
  read -r namespace name tag <<< "$(printf "%b" "$1\x34$2\x34$3")"

  # create <name> [options]
  if [ -z "$name" ]; then
    errmsg "Name is empty. You must specify a name"
    return 1
  fi

  buf=$(snapshot_buildcmds "$name")
  errno=$?
  if [ $errno -ne 0 ]; then
    errmsg "Error. Could not build commands to run. Errno: $errno"
    if [ $errno -eq 100 ]; then
      errmsg "No match found for '$name'."
      errmsg "Check your configuration file '$(cfg_get "confman")'"
    fi
    return $errno
  fi
  
  # Get destination directory and initialize it if not existing
  destdir=$(snapshot_destdir "$namespace")
  snapshot_initdestdir "$destdir"
  errno=$?
  if [ $errno -ne 0 ]; then
    errmsg "Error. Unable to create destdir '$destdir'. Errno: $errno"
    return 1
  fi

  # Create snapshot backup for an existing snapshot
  # The backup file will be restored in case of an error
  local filename
  filename=$(snapshot_filename "$namespace" "$name" "$tag")

  # Replace {{filename}} token with actual filename value
  buf=$(printf "%s" "$buf" | sed "s#{{filename}}#$destdir/$filename.tmp#")

  # All data is stored in an intermediary file first
  # This gives the opportunity to recover from unforeseen errors
  # The intermediary file is deleted if already present
  if test -f "$destdir/$filename.tmp"; then
    echo "Removing intermediary temporary file: $destdir/$filename.tmp"
    rm "$destdir/$filename.tmp"
  fi

  # Print Tar commands if --dryrun option is requested
  # This will NOT prevent deleting temporaries or creating directories
  if cfg_testflags "opts" "$F_DRYRUN"; then
    echo "Dry-run requested. Commands to be executed shown below:"
    printf "%b\n" "$buf"
    return 0
  fi
  
  local cmd cmds
  IFS=$'\x0a'
  read -d '' -r -a cmds <<< $"$(printf "%b" "$buf")"
  for cmd in "${cmds[@]}"; do
    eval "$cmd"
    errno=$?
    if [ $errno -ne 0 ]; then
      errmsg "Could not execute command: '$cmd' Errno: $errno"
      break
    fi
  done

  if [ $errno -ne 0 ]; then
    return $errno
  fi

  ## Compress tarball with gzip
  gzip -f -9 --no-name "$destdir/$filename.tmp" 2>/dev/null
  errno=$?
  if [ $errno -ne 0 ]; then
    errmsg "Error while executing gzip command. Errno: $errno"
    return $errno
  fi

  # Calculate file checksum
  digest=$(sha256sum "$destdir/$filename.tmp.gz" | awk '{ print $1 }')

  # Verify tarball integrity
  echo "Verifying tarball integrity '$destdir/$filename.tmp.gz'"
  gunzip -c "$destdir/$filename.tmp.gz" | tar -t > /dev/null
  errno=$?
  if [ $errno -ne 0 ]; then
    errmsg "Unable to verify tarball. Errno: $errno"
    return $errno
  fi

  # remove previous version file
  local files file
  IFS=$'\n'
  read -d '' -r -a files <<< \
    "$(find "$destdir" -type f -name "$filename*.tar.gz")"
  for file in "${files[@]}"; do
    echo "Removing file: '$file'"
    rm "$file"
    errno=$?
    if [ $errno -ne 0 ]; then
      errmsg "Operation failed: '$file'. Errno: $errno"
      break
    fi
  done
  
  # make the final move
  mv "$destdir/$filename.tmp.gz" "$destdir/$filename--$digest.tar.gz"
  errno=$?
  if [ $? -ne 0 ]; then
    errmsg "Error while moving temporary: '$destdir/$filename--$digest.tmp.gz'. Errno: $errno"
    return $errno
  fi

  echo "OK. Snapshot: '$destdir/$filename-$digest.tar.gz'."
  return 0
}

snapshot_find_dirs_(){
  if [ ! -d "$1/" ]; then
    echo ''
    return 1
  fi
  printf "%s\n" \
    "$(find "$1/" -mindepth 1 -maxdepth 1 -type d)"
}

snapshot_find_files_(){
  local buf
  while read -r buf; do
    if [ -z "$buf" ]; then
      continue
    fi
    printf "%s\n" \
      "$(find "$buf" -type f -name '*.tar.gz' -printf '%p\n')"
  done <<< "$(</dev/stdin)"
}

# char* snapshot_filter_namespace (namespace)
snapshot_filter_namespace(){
  # Return original buffer if no namespace specified
  if [ -z "$1" ]; then 
    echo "$(</dev/stdin)"
    return 1
  fi

  # filter by namespace
  local basename
  while read -r buf; do
    basename=$(basename "$buf")
    if [ "$1" = "$basename" ]; then
      printf "%s\n" "$buf"
    fi
  done <<< "$(</dev/stdin)"
}

snapshot_filter_file_(){
  local buf basename

  local fs rs; fs=$CONFMAN_FS; rs=$'\x0a'
  while read -r buf; do
    basename="$(basename "$buf" | sed s/.tar.gz//)"
    IFS="$fs"; read -r -a basename <<< "${basename//--/$fs}"
    
    printf "%s$fs%s$fs%s$fs%s${rs}" \
        "${basename[0]}" \
        "${basename[1]}" \
        "${basename[2]}" \
        "${basename[3]}"
  
  done <<< "$(</dev/stdin)"
}

# char* snapshot_find_ (cachedir, namespace)
snapshot_find_(){
  snapshot_find_dirs_ "$1" \
    | snapshot_filter_namespace "$2" \
    | snapshot_find_files_ \
    | snapshot_filter_file_ 
}

# Output format is <name> <namespace> <tag> <hash>
#                   idx0      1         2      3
# value at idex 1 is namespace etc
# its a way to map values and filter them
snapshot_filter_index(){
  # Discard empty input
  if [ -z "$2" ]; then
    echo "$(</dev/stdin)"
    return 1
  fi

  local buf arr
  IFS=$CONFMAN_FS
  while read -r buf; do
    read -r -a arr <<< "$buf"
    if [ "$2" != "${arr[$1]}" ]; then
      continue
    fi
    echo "$buf"
  done <<< "$(</dev/stdin)"
}

snapshot_filter_tag(){
  snapshot_filter_index "2" "$1"
}

snapshot_filter_name(){
  snapshot_filter_index "0" "$1"
}

# filter by hash
# minimum 2 chars required
snapshot_filter_hash(){
  # Discard non-hex input
  if [ "$(expr "$1" : "^[[:xdigit:]]\{2,\}$")" -eq 0 ]; then
    #echo "$(</dev/stdin)"
    return 1
  fi

  local buf arr
  IFS="$CONFMAN_FS"
  while read -r buf; do
    read -r -a arr <<< "$buf"
    if [ -n "$1" ] && [ "$(expr "${arr[3]}" : "$1")" -eq 0 ]; then
      continue
    fi
    echo "$buf"
  done <<< "$(</dev/stdin)"
}

snapshot_file_details_(){
  local dir buf a t
  local filename
  local created size id

  dir="$1"
  local fs rs; fs="$CONFMAN_FS"; rs=$'\x0a'
  while read -r buf; do

    if [ -z "$buf" ]; then
      continue
    fi

    IFS="$fs"; read -r -a a <<< "$buf"

    filename="$dir/${a[1]}/${a[0]}--${a[1]}--${a[2]}--${a[3]}.tar.gz"
    
    t="$(stat -c "%W" "$filename")"
    created="$(date -d "@$t" +"%Y-%m-%d %H:%M")"
    size="$(du -k "$filename" | cut -f1)"
    printf "%s$fs%s$fs%s$fs%s$fs%s$fs%s${rs}" \
        "${a[1]}" \
        "${a[0]}" \
        "${a[2]}" \
        "${a[3]:0:12}" \
        "$created" \
        "$size KB"
  done <<< "$(</dev/stdin)"
}

snapshot_ls_(){
  local dir ns name tag

  dir="$1"
  ns="$2"
  name="$3"
  tag="$4"
 
  # Find by checksum
  snapshot_find_ "$dir" \
    | snapshot_filter_hash "$name"
  
  if [ $? -ne 0 ]; then
    snapshot_find_ "$dir" "$ns" \
      | snapshot_filter_tag "$tag" \
      | snapshot_filter_name "$name"
  fi
}

snapshot_ls(){
  local dir ns name tag
  
  dir="$1"
  ns="$2"
  name="$3"
  tag="$4" 

  local fs rs; fs="$CONFMAN_FS"; rs=$'\n'
  printf "%s${fs}%s${fs}%s${fs}%s${fs}%s${fs}%s${rs}" \
    "NAMESPACE" "NAME" "TAG" "ID" "CREATED" "SIZE"

  snapshot_ls_ "$dir" "$ns" "$name" "$tag" \
    | snapshot_file_details_ "$dir"
}

snapshot_rm(){
  local namespace
}
