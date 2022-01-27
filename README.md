# confman
Utility for easy snapshotting and restoring arbitrary data

## Why confman?

It helps to make snapshot of configuration data easily.

Consider the following configuration example:

```
vim {
  .vimrc
  .vim/
}
```

The above directives will instruct `confman` to create a snapshot of the files within the brakets and tar.gz them for you

## Basic usage

Confman can be run directly using the command line.

```sh
# A .confman file will be searched within the same path of the current working directory $PWD
confman
```

```sh
# set configuration file manually using -f or --file option
confman -f /home/myuser/.confman
```

