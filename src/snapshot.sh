
snapshot_id(){
  #echo $(date +%Y-%d-%b) | tr '[:upper:]' '[:lower:]'
  echo $(date +%s)
}

##
# Create tarball and gzip it using attributes such as TAG
# int snapshot_create (tag)
##
snapshot_initdir(){
  if [ ! -d "$1" ]; then
    echo "Creating snapshot cache directory: $1"
    mkdir -p "$1"
  fi
}

snapshot_getdestdir(){
  echo "$(cfg_get "cachedir")/$1"
}

# Resolve the filename for each snapshot
# void getfilename (namespace, name, tag)
snapshot_filename(){
  local namespace name tag

  namespace="$1"
  name="$2"
  tag="$3"

  echo "${name}_${namespace}_${tag}"
}

# check if snapshot exists
# int exists(filename)
snapshot_exists(){
  echo "checking if '$1' exists..."
  if [ -f "$1" ]; then
    return 0
  fi
  
  return 1
}

snapshot_create(){
  local buf destdir
  local namespace name tag
 
  read -r namespace name tag <<< $(echo "$1" "$2" "$3")
  echo "snapshot create invoked with <ns:$namespace> <name:$name> <tag:$tag>"

  # create <name> [options]
  if [ -z "$name" ]; then
    errmsg "Name is empty. You must specify a name"
    return 1
  fi

  buf=$(confman_parse $(cfg_get "confman"))
  if [ $? -ne 0 ]; then
    errmsg "An error has occurred while parsing the configuration file"
    return 1
  fi

  # get destination directory for snapshots
  destdir=$(snapshot_getdestdir "$namespace")

  # Create snapshot backup for an existing snapshot
  # The backup file will be restored in case of an error
  local filename
  filename=$(snapshot_filename "$namespace" "$name" "$tag")

  # check if intermediary temporary file exists
  if snapshot_exists "$destdir/$filename.tar.gz.tmp" ; then
    echo "removing intermediary temporary file: $destdir/$filename.tmp"
    rm "$destdir/$filename.tmp"
  fi
  
  ##
  # Iterate through parsed configuration data
  local records fields sbuf

  # Get records for a specific <name>. Ex. name=vim
  records=$(confman_read_records \
    $(confman_getname "$buf" "$name"))
  
  # Iterate though every record
  echo "Processing $name with $namespace"
  for record in ${records[@]}; do
    fields=( $(confman_read_fields "$record") )
    if [ "${fields[0]}" = "add" ]; then
      sbuf="${sbuf}tar -v --append --file=\"$destdir/$filename.tar\" \"${fields[1]}\"\n"
      #echo "filename to tar is: '${fields[1]}'"
    fi
  done

  # Remove last newline character (\ + n) == 2 chars
  sbuf="${sbuf::-2}"

  if cfg_testflags "opts" "$F_DRYRUN"; then
    echo "Dry-run requested."
    echo -e "Commands to be executed shown below:\n$sbuf"
    return 0
  fi
  echo "todo"
  exit
  local fn
  fn=$(confman_getfunction "$name")
  if [ $? -ne 0 ]; then
    errmsg "$name does not exist"
    return 1
  fi

  # Create destination directory if this doesnt exist
  # pattern: <cachedir>/<namespace>
  snapshot_initdir "$dstdir"

  # Set the Confman destination directory
  # This variable is used by the __cm_<name>() function
  CM_DSTDIR="$dstdir"
  eval "$fn"
#snapshot_initdir "$dstdir"
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
  local namespace group tag cachedir

  namespace="$1"
  cachedir=$(cfg_get "cachedir")

  #echo "$(ls -laA "$cachedir/$namespace")"

  echo "$(snapshot_ls_ "$cachedir/$namespace")"


}
