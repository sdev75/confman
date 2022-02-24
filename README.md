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

Confman uses a repository directory, which is a directory that keeps snappshots organized. This directory is structured as follows:

```sh
.cache/confman/<NAMESPACE>/<FILENAME>
```

The default repository directory is `$HOME/.cache/confman`. This can be overriden by using the options `--repo`.


## Anatomy of configuration file
A configuration file acts as set of rules to map several files into groups or collections. These can be aggregated further using namespaces. We will see how to do this soon.

Here is a pseudo configuration data:

```
name1 {
  relative/path/to/my/file.ext
  /absolute/path/to/my/other/file.ext
  directories/end/up/with/slashes/
}

name2 {
  <file>
  <directory>/
}
```

## Manual configuration file
A configuration file can be explicitly set using the option `--config` or the short version `-c`

```sh
confman -c /etc/.confman
```

## Basic usage
### Snapshot
Snapshots are archived data with gzip compression. They are stored structurally within the repository directory of confman. They can be moved, copied, saved and restored. More details will come in the future.

A repository directory can be set with the `--repodir` flag:

```sh
confman --repodir /my/repodir
```

#### Snapshot Create
A snapshot can be created by using the `create` action. This takes a mandatory `name` parameter used to specify the target of the snapshot, or the final name used to store the archived gzipped data.

```sh
confman create vim
```

#### Namespaces and Tags
Snapshots can be aggregated using namespaces and tags. These can be passed in as optional parameters when creating a snapshot.

```sh
confman create vim [tag [namespace]]
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
List information about snapshots created. There are seveal possibile ways to filter the data. Below are a few example:

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

It is possible to print the filenames only without any tables. Useful for handling the data with a script.

```sh
confman ls vim --printf '%p\n'

# looping through files
for filename in $(confman ls vim --printf '%p\n'); do echo "$filename"; done
```

Bear in mind this tool is written in shell scripting language, thus these formatting and commands might be quite slow to process. Usually around 0.1 seconds on average. I find this to be acceptable considering this utility will only be used for performing seldom backups.

#### Copying snapshots
A snapshot can be copied to a destination directory. This is useful when doing backups for specific snapshots.
When copying a snapshot, the name of the snapshot along with a destination directory are mandatory arguments.
The `name` field will attempt to match a valid name, including but not limited to a checksum value. It's important to notice that if multiple snapshots are matched, all the matched snapshots will be copied to the destination folder. Therefore, attention should be paid when entering a name value to avoid
ambiguity whenever possible.

```sh
confman cp NAME [TAG [NAMESPACE]] DESTDIR
```

An optional tag and namespace can be passed in using the `-t` and `-n` flags accordingly. Empty values will match everything. 

More examples:

```sh
# Copy a snapshot having the checksum with the digits "289" and tag "latest" into /home/backups/<filename>.tar.gz
confman cp 289 latest /home/backups

# Copy all snapshots having a specific namespace and a tag
confman cp vim tag1 namespace1 /home/backups

# Copy all snapshots having a specific tag with any namespaces
confman cp vim tag2 -n "" /home/backups

# Copy all snapshots by name regardless of tag and namespace (empty values match everything)
confman cp vim -t "" -n "" /home/backups

# Copy all snapshots with any tag and specific namespace
confman cp vim -t "" -n "mynamespace" /home/backups
```

#### Importing  a snapshot

It's possible to import a snapshot from an existing file. The only requirements to follow is the naming of the file as follows:

```
<name>--<namespace>--<tag>--<checksum>.tar.gz
```

Restoring a snapshot will simply parse the filename and store it within the active `repodir` within the correct folder structure. It is possbile to overwrite the naming parameters with the `-t` flag for setting a tag, `-n` flag for the namespace and a name to override the data while importing.

```sh
confman import <filename>
confman import <filename> -t test -n mynamespace
confman import <filename> name1 -t tag2
```

### More to come
More details will be added here
