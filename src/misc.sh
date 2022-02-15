
declare -a HELPTEXT=("
Usage confman [OPTIONS]

Global Options:
  -h, --help      Prints this message
  -c, --config      Configuration file to read
      --parse     Parse configuration, print it then exit
      --dryrun    Show commands to be executed without executing them
  -f, --force     Force certain operations, such as overwriting existing files

Snapshot Commands:
      create      Usage: confman create [name [tag [namespace]]]
  ls, list        Usage: confman ls [name [tag [namespace]]]
  rm, remove      Usage: confman rm [name [tag [namespace]]]
  cp, copy        Usage: confman cp [name [tag [namespace]]] destdir
      restore     Usage: confman restore filename [name [tag [namespace]]]

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
