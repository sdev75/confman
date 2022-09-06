
declare -a HELPTEXT=("
Usage confman [OPTIONS]

Global Options:
  -h, --help      Prints this message
  -c, --config    Configuration file to read
      --repodir   Use a specific repository directory
      --dryrun    Show commands to be executed without executing them
  -f, --force     Force certain operations, such as overwriting existing files
      --printf    Print format snapshots list
                    format flags:
                      %p = snapshot filename
                      %n = snapshot name
                    example: confman ls [name] --printf "%p\n"

Configuration Commands:
      parse       Parse configuration, print it then exit

Snapshot Commands:
      create      Usage: confman create [name [tag [namespace]]]
  ls, list        Usage: confman ls [name [tag [namespace]]]
  rm, remove      Usage: confman rm [name [tag [namespace]]]
  cp, copy        Usage: confman cp [name [tag [namespace]]] destdir
      import      Usage: confman import filename [name [tag [namespace]]
      restore     Usage: confman restore filename [name [tag [namespace]]]
      peek        Usage: confman peek name [what]

Snapshot Scanning:
  Scanning allows confman to search for files within the repodir or within a specified directory
  All files mathing the naming pattern will be reorganized within the confman repository.
  Existing snapshots will not be imported unless forced to do so excplitily with the --force flag
      scan        Usage: confman scan [srcdir]  

Snapshot Options:
  -t, --tag       Set snapshot tag value
  -n, --ns        Set snapshot namespace value
")

errmsg(){
  exec 1>&2
  printf "%b\n" "\x1b[0;31m$1\x1b[0m"
}

help(){
  echo "${HELPTEXT[0]}"
  exit "$1"
}
