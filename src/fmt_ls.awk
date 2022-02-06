BEGIN {
  OFS = ofs
  ORS = "\n"
  print "PERMISSIONS","SIZE","CREATED","NAMESPACE","NAME","TAG","ID"
}
{
  FS = " "
  # %W created since epoch
  # %Y modified since epoch
  cmd = "stat -c \"%n\x1d%U\x1d%G\x1d%A\x1d%W\x1d%Y\" " current_dir "/" $1
  cmd | getline buf
  close(cmd)

  FS = ofs
  $0 = buf
  
  filename=$1
  group=$2
  user=$3
  perms=$4
  created_at=$5
  datefmt = "date -d \"@" created_at"\" +\"%Y-%m-%d %H:%M\""

  datefmt | getline created_at
  close(datefmt)
 
  cmd = "du -k " filename " | cut -f1"
  cmd | getline size
  close(cmd)

  n = split (filename, a, "/", seps)
  basename = a[n]
  
  n = split (basename, a, "--", seps)
  
  if (n < 4) {
    next;
  }

  name = a[1]
  namespace = a[2]
  tag = a[3]
  checksum = a[4]
  id = substr(checksum,0,12)
  
  print perms " " user "/" group,size "KB",created_at,namespace,name,tag,id
}
