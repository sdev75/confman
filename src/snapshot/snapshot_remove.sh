snapshot_remove(){
  local repodir name tag ns

  repodir="$1"; ns="$2"; name="$3"; tag="$4"

  echo "repo: $repodir ns $ns name $name tag $tag"
  local files
  files="$(snapshot_list_ "$repodir" "$ns" "$name" "$tag")"

  echo "files:"
  echo "$files"
}
