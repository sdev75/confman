# extract snapshot contents
# int snapshot_extract (repodir, name, tag, namespace, what, where)
# what is the file path to extract from
# where is the path to extract `what` to
# example tar -zxf <file> -C <where> <what>
snapshot_extract(){
  local repodir name tag ns
  repodir="$1"
  name="$2" tag="$3" ns="$4"
  what="$5" where="$6"

  echo "repodir $repodir, what $what where $where"

}
