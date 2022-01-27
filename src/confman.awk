
function getfilename (groupid){
  return "${CACHEDIR}/${SNAPSHOTID}/" groupid ".tar"
}

function gettarcmd (src, dst){
  return "tar -v --append --file=\"" dst "\" \""  src "\""
}

function getgzipcmd (filename){
  return "gzip -9 \"" filename "\""
}

BEGIN {
  group_idx = 0
  group_cmds = 0
}
{
  if ($0 ~ /[[:alnum:]]+ *{/) { 
    #  print "gzip -9 " filename

    match($0,/^([a-z]+).*/,m)
    
    groupid = m[1]
    groups[groupid] = 0
    gensub(/^([a-z]+).*/,"__\\1(){", "g")
  
  } else {
    
    if (NF == 1){
      if ($1 != "}"){
        cmd = "add"
        src = $1
      }
    }else{
      cmd = $1
      src = $2
    }
    if (cmd == "add") {
      idx = groups[groupid]
      groupcmds[groupid][idx] = gettarcmd(src,getfilename(groupid))
      groups[groupid] += 1
    }
  }

}
END {
  print "#!/usr/bin/env sh"
  print "# Generated by Confman. Link: github.com/sdev75/confman"
  
  # Add confman file automatically
  groupcmds["confman"][0] = gettarcmd(".confman", getfilename("confman"))
  
  # Iterate through all the groups and build data
  for (groupid in groupcmds){
    print "__cm_" groupid "(){"
    for (i=0; i < length(groupcmds[groupid]); i++){
      print  groupcmds[groupid][i]
    }
    #print getgzipcmd(getfilename(groupid))
    print "}"
  }
}
