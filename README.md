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

## Synopsis
```sh
confman [ACTION] [OPTION...]
```

## Description
Confman searched for a `.confman` file within the current working directory. If the `.confman` file is not found, it will traverse each parent directory until it either find one or it reaches the root directory. In that case the application will exit with an error code.

## Anatomy of configuration file
A configuration file acts as set of rules to map several files into groups or collections. These can be aggregated further using namespaces. We will see how to do this soon.

Here is a pseudo configuration data:

```

group1 {
  relative/path/to/my/file.ext
  /absolute/path/to/my/other/file.ext
  directories/end/up/with/slashes/
}

group2 {
  <file>
  <directory>/
}
```

## Manual configuration file
A configuration file can be explicitly set using the option `--file` or the short version `-f`

```sh
confman -f /etc/.confman
```

## Basic usage

### Snapshot

Snapshots are archived data with gzip compression. They are stored structurally within the cache directory of confman. They can be moved, copied, saved and restored. More details will come in the future.

#### Snapshot Create

A snapshot can be created by using the `create` action. This takes a mandatory `name` parameter used to specify the target of the snapshot, or the final name used to store the archived gzipped data.

```sh
confman create vim
```

#### Namespaces and Tags
Snapshots can be aggregated using namespaces and tags. These can be passed in as optional parameters when creating a snapshot.

```sh
confman create vim [namespace [tag]]
```

A tag can also be passed in using the `-t` option.

```sh
confman create vim -t 1.0 [namespace]
```

#### Snapshot Output Format
A snapshot is a simple tarball created using the `tar` command. The tarball is then gzipped and hashed using the sha256 algorithm to provide a level of integrity check. The gzipped archive is further tested for errors by performing an extract operation to /dev/null as follows:

```sh
gunzip -c <filename> | tar -t /dev/null
```

The default output format is the following:

```sh
<destdir>/<namespace=default>/<name>--<namespace>--<tag=latest>--<digest>.tar.gz
```

#### Listing Snapshots

List information about snapshots created. Thes are seveal possibile ways to filter the data. Below are a few example:

```sh
# Print everything
confman ls

# Filter by name
confman ls vim

# Filter by ID (it uses regexp; min 3 digits)
confman ls <checksum>

# Filter by name and tag
confman ls <name> <tag>

# Filter by name, tag and namespace
confman ls <name> <tag> <namespace>

# Filter by namespace and tag
confman ls -t <tag> -n <namespace>
```

### More to come

More info will be added here.
