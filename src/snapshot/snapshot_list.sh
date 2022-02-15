
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

snapshot_transform_split_filename_(){
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

# char* snapshot_find_ (repodir, namespace)
# Output format: <name> <ns> <tag> <checksum>
snapshot_find_(){
  snapshot_find_dirs_ "$1" \
    | snapshot_filter_namespace "$2" \
    | snapshot_find_files_ \
    | snapshot_transform_split_filename_
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

snapshot_details_(){
  local buf a t
  local filename
  local created size id

  local fs rs; fs="$CONFMAN_FS"; rs=$'\x0a'
  while read -r buf; do
    if [ -z "$buf" ]; then
      continue
    fi

    IFS="$fs"; read -r -a a <<< "$buf"

    if [ "${a[1]}" = "" ]; then
      break
    fi

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

snapshot_list_(){
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

snapshot_list(){
  local dir ns name tag
  
  dir="$1"
  ns="$2"
  name="$3"
  tag="$4" 
  
  local fs rs; fs="$CONFMAN_FS"; rs=$'\n'
  printf "%s${fs}%s${fs}%s${fs}%s${fs}%s${fs}%s${rs}" \
    "NAMESPACE" "NAME" "TAG" "ID" "CREATED" "SIZE"

  snapshot_list_ "$dir" "$ns" "$name" "$tag" \
    | snapshot_details_
}

