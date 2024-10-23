# `eleveldb` - Erlang bindings to LevelDB datastore 

[![Build Status](https://github.com/OpenRiak/eleveldb/actions/workflows/erlang.yml/badge.svg)](https://github.com/OpenRiak/eleveldb/actions/workflows/erlang.yml)

This project provides Erlang bindings to a LevelDB datastore heavily optimised for [Riak workloads](https://github.com/OpenRiak/riak).
See the [Riak LevelDB wiki](https://github.com/OpenRiak/leveldb/wiki) for a breakdown of the optimisations.

## Future Development

No further work on optimising the underlying store is currently being undertaken, only minimal fixes necessary for platform compatibility.

At present, this backend is slated for deprecation in [OpenRiak](https://github.com/OpenRiak) 3.4 and removal in a subsequent release.
Should a maintainer commit to ongoing support that strategy will be revisited.

### Alternatives

* For Riak-like workloads, especially with large objects, the pure-Erlang [LevelEd store](https://github.com/martinsumner/leveled) is recommended.
* Erlang bindings to RocksDB can be found as part of the [BarrellDB](https://gitlab.com/barrel-db/erlang-rocksdb) project.

# Iterating Records

## High-level Iterator Interface

The interface that most clients of eleveldb should use when iterating over a set of records stored in leveldb is `fold`, since this fits nicely with the Erlang way of doing things.

For those who need more control over the process of iterating over records, you can use direct iterator actions. Use them with great care.

## Direct Iterator Actions

### seek/next/prev

- **seek:** Move iterator to a new position.

- **next:** Move forward one position and return the value; do nothing else.

- **prev:** Move backward one position and return the value; do nothing else.

### prefetch/prefetch_stop

- **prefetch:** Perform a `next` action and then start a parallel call for the subsequent `next` while Erlang processes the current `next`. The subsequent `prefetch` may return immediately with the value already retrieved.

- **prefetch_stop:** Stop a sequence of `prefetch` calls. If there is a parallel `prefetch` pending, cancel it, since we are about to move the pointer.

### Warning

Either use `prefetch`/`prefetch_stop` or `next`/`prev`.  Do not intermix `prefetch` and `next`/`prev`.  You must `prefetch_stop` after one or more `prefetch` operations before using any of the other operations (`seek`, `next`, `prev`).

