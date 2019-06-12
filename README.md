# LoggerEtsBackend

[![current build status on Travis-CI.org][build_status]][1]

A simple `Logger` backend which writes logs to an ETS table.
It does not create or manage the table for you; you must do
this external to the logging app.

`LoggerEtsBackend` borrows heavily from [`LoggerFileBackend`][2], and
therefore acts much the same way.

## Rationale

The primary use-case for this backend is _not_ for persistent logs,
but for temporary logs that may need to be inspected at run-time by
the system itself. By pushing log messages to an ETS table, data
can be quickly searched using `match_spec`s based on message contents
or the metadata stored along with the entry.

## Configuration

`LoggerEtsBackend` is a custom backend for the elixir `:logger`
application. This backend can only log to a single ETS table, so there
must be one `:logger` backend configured for each log file we need. Each
backend has a name like `{LoggerEtsBackend, id}`, where `id` is any
elixir term (usually an atom).

**Note:** tables use for logging are recommented to be configured with the
`:ordered_set` and `:public` options.

### Configuration Example

```elixir
config :logger,
  backends: [{LoggerEtsBackend, :inspection_log}]

# configuration for the {LoggerEtsBackend, :critical_log} backend
config :logger, :critical_log,
  table: :critical_table,
  level: :error
```

## Usage

`LoggerEtsBackend` supports the following configuration values:

* `table` - the table name to push log tuples to
* `level` - the logging level for the backend
* `metadata` - the metadata to include
* `metadata_filter` - metadata terms which must be present in order to log

**Note:** It is recommended that `metadata_filter` is set for this
backend, to ensure only a small subset of log entries are captured.

### Examples

#### Runtime configuration

```elixir
# some process starts an ets table
:ets.new(:debug_messages, [:ordered_set, :public, :named_table])
...
Logger.add_backend {LoggerFileBackend, :debug}
Logger.configure_backend {LoggerFileBackend, :debug},
  table: :debug_messages,
  metadata: ...,
  metadata_filter: ...
```

#### Application config for multiple log files

```elixir
config :logger,
  backends: [{LoggerEtsBackend, :info},
             {LoggerEtsBackend, :error}]

config :logger, :info,
  table: :info_messages,
  level: :info

config :logger, :error,
  table: :error_messages,
  level: :error
```

#### Filter out metadata

This example removes all the default metadata and only keeps the
`:module` name which issued the log message.

```elixir
config :logger,
  backends: [{LoggerEtsBackend, :info}]

config :logger, :info,
  table: :info_messages,
  level: :info,
  metadata: [application: :ui]
```

#### Filtering logging by specifying metadata terms

This example only logs `:info` statements originating from the `:ui`
OTP app. The `:application` metadata key is auto-populated by `Logger`.

```elixir
config :logger,
  backends: [{LoggerEtsBackend, :ui}]

config :logger, :ui,
  table: :ui_messages,
  level: :info,
  metadata_filter: [application: :ui]
```


[1]: https://travis-ci.org/OldhamMade/logger_ets_backend
[2]: https://github.com/onkel-dirtus/logger_file_backend
[build_status]: https://travis-ci.org/OldhamMade/logger_ets_backend.svg?branch=master
