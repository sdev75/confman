BEGIN {
  OFS=":"
  ORS="\n"
  print "NAMESPACE","FILE","TAG","GROUP","OWNER","PERMS","CREATED","MODIFIED","SIZE"
}
{
  # %W created since epoch
  # %Y modified since epoch
  cmd = "stat -c \"%A:%G:%U:%n:%W:%Y\" " current_dir "/" $1
  cmd | getline buf
  close(cmd)
  
  FS=":"
  $0=buf
  print "<NSHERE>",$4,"<TAGHERE>",$2,$3,$1,$5,$6,"<BYTES>"
  FS=" "
}
