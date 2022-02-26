
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
  local basename

  local IFS
  IFS=$CONFMAN_RS
  read -r -a records <<< "$buf"
  for record in "${records[@]}"; do
    IFS="$CONFMAN_FS"
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
    parentdir="$(realpath "${src}")"
    basename="$(basename "$parentdir")"
    parentdir="$(dirname "$parentdir")"
    #t1=$(printf "%s" "$src" | sed "s#$parentdir/##")
    t2="tar --append --file=\"{{filename}}\""
    sbuf="${sbuf}${t2} -C \"$parentdir\" \"$basename\"\n"
  done
  
  if [ -z "$name_" ]; then
    return 100
  fi

  printf "%b" "$sbuf"
  return 0
}

# create name [tag [namespace]]
snapshot_create(){
  local buf destdir errno
  local ns name tag
  
  local IFS=$'\x1f'; read -r ns name tag \
    <<< "$(printf "%b" "$1\x1f$2\x1f$3")"

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
  destdir=$(snapshot_destdir "$ns")
  snapshot_initdestdir "$destdir"
  errno=$?
  if [ $errno -ne 0 ]; then
    errmsg "Error. Unable to create destdir '$destdir'. Errno: $errno"
    return 1
  fi

  # Create snapshot backup for an existing snapshot
  # The backup file will be restored in case of an error
  local filename
  filename="$(snapshot_filename "$ns" "$name" "$tag")"
  
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
