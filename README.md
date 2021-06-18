# LoggerEtsBackend

![CI][ci-badge] [![Coverage Status][coverage-badge]][coverage-link]

<!-- MDOC !-->

A simple `Logger` backend which writes log entries to ETS, primarily
for runtime inspection.

Note: It does not create or manage the target log table(s) for you; you
must do this as part of your own application.

`LoggerEtsBackend` borrows heavily from
[`LoggerFileBackend`][logger_file_backend], and therefore acts in much
the same way.

## Rationale

The primary use-case for this backend is _not_ for persistent logs,
but for temporary logs that need to be inspected at run-time by the
system itself. By pushing log messages to an ETS table, data can be
quickly searched using `match_spec`s based on message contents or the
metadata stored along with the entry.

## Configuration

`LoggerEtsBackend` is a custom backend for the elixir `:logger`
application. This backend can only log to a single ETS table, so there
must be one `:logger` backend configured for each log file we
need. Each backend has a name like `{LoggerEtsBackend, id}`, where
`id` is any elixir term (usually an atom).

**Note:** tables use for logging are recommented to be configured with
the `:ordered_set` and `:public` options.

### Configuration Example

```elixir
config :logger,
  backends: [{LoggerEtsBackend, :events_log}]

# configuration for the {LoggerEtsBackend, :events_log} backend
config :logger, :events_log,
  table: :events_log_table,
  level: :error
```

## Usage

`LoggerEtsBackend` supports the following configuration values:

* `table` - the table name to push log tuples to
* `level` - the logging level for the backend
* `metadata` - the metadata to include
* `metadata_filter` - metadata terms which must be present in order to
  log

**Note:** It is recommended that `metadata_filter` is set for this
backend, to ensure only a small subset of log entries are captured.

<!-- MDOC !-->

### Examples

#### Runtime configuration

```elixir
# some process starts an ets table
:ets.new(:debug_messages, [:ordered_set, :public, :named_table])

# then we configure the backend
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
OTP app. The `:application` metadata key is auto-populated by
`Logger`.

```elixir
config :logger,
  backends: [{LoggerEtsBackend, :ui}]

config :logger, :ui,
  table: :ui_messages,
  level: :info,
  metadata_filter: [application: :ui]
```

#### Storing keyword data (Elixir ~> 1.11)

Configuration:

```elixir
config :logger,
  backends: [{LoggerEtsBackend, :ui}]

config :logger, :ui,
  table: :ui_messages,
  level: :info,
  metadata_filter: [application: :ui]
```

Usage (example from an `iex -S mix phx.server` instance):

```elixir
iex(1)> require Logger
Logger
iex(2)> Logger.info([screen: :dashboard, scope: :global], application: :ui)
:ok
iex(3)> :ets.lookup(:ui_log, :ets.last(:ui_log))
[
  {{{2021, 6, 18}, {6, 59, 18, 173}}, :info, [screen: :dashboard, scope: :global],
   [
     erl_level: :info,
     application: :ui,
     domain: [:elixir],
     gl: #PID<0.66.0>,
     pid: #PID<0.1138.0>,
     time: 1623992358173152
   ]}
]
```

## Contributing

**Note: the project is made & maintained by a small team of humans,
who on occasion may make mistakes and omissions. Please do not
hesitate to point out if you notice a bug or something missing, and
consider contributing if you can.**

The project is managed on a best-effort basis, and aims to be "good
enough". If there are features missing please raise a ticket or create
a Pull Request by following these steps:

1.  [Fork it][fork]
2.  Create your feature branch (`git checkout -b my-new-feature`)
3.  Commit your changes (`git commit -am 'Add some feature'`)
4.  Push to the branch (`git push origin my-new-feature`)
5.  Raise a new pull request via GitHub

## Liability

We take no responsibility for the use of our tool, or external
instances provided by third parties. We strongly recommend you abide
by the valid official regulations in your country. Furthermore, we
refuse liability for any inappropriate or malicious use of this
tool. This tool is provided to you in the spirit of free, open
software.

You may view the LICENSE in which this software is provided to you
[here](./LICENSE).

> 8. Limitation of Liability. In no event and under no legal theory,
>    whether in tort (including negligence), contract, or otherwise,
>    unless required by applicable law (such as deliberate and grossly
>    negligent acts) or agreed to in writing, shall any Contributor be
>    liable to You for damages, including any direct, indirect, special,
>    incidental, or consequential damages of any character arising as a
>    result of this License or out of the use or inability to use the
>    Work (including but not limited to damages for loss of goodwill,
>    work stoppage, computer failure or malfunction, or any and all
>    other commercial damages or losses), even if such Contributor
>    has been advised of the possibility of such damages.


[logger_file_backend]: https://github.com/onkel-dirtus/logger_file_backend
[ci-badge]: https://github.com/OldhamMade/logger_ets_backend/workflows/CI/badge.svg
[coverage-badge]: https://coveralls.io/repos/github/OldhamMade/logger_ets_backend/badge.svg?branch=main
[coverage-link]: https://coveralls.io/github/OldhamMade/logger_ets_backend?branch=main
[fork]: https://github.com/OldhamMade/logger_ets_backend/fork
