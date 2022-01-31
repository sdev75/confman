BEGIN {
  OFS = ofs
  ORS = "\n"
  print "PERMISSIONS","SIZE","MODIFIED","NAMESPACE","TAG","FILENAME"
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
  datefmt = "date -d \"@" $5 "\" +\"%Y-%m-%d %H:%M\""
  datefmt | getline created_at
  close(datefmt)

  datefmt | getline modified_at
  close(datefmt)
  
  print perms " " user "/" group,"<size>",modified_at,"<namespace>","<tag>",filename
}
