defmodule LoggerEtsBackend do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @behaviour :gen_event

  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  def handle_call({:configure, opts}, %{name: name} = state) do
    {:ok, :ok, configure(name, opts, state)}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, state) do
    %{level: min_level, metadata_filter: md_filter} = state

    if min_level_met?(level, min_level) and metadata_matches?(md, md_filter),
      do: log_event(level, msg, ts, md, state)

    {:ok, state}
  end

  def handle_event(_, state), do: {:ok, state}
  def handle_info(_, state), do: {:ok, state}

  defp log_event(level, msg, ts, md, state) do
    %{table: table, metadata: md_keys} = state

    data =
      case state.store_keywords do
        true -> maybe_parse_msg(msg)
        _ -> msg
      end

    filtered_md = take_metadata(md, md_keys)

    :ets.insert_new(table, {ts, level, data, filtered_md})
  rescue
    ErlangError ->
      # table doesn't exist or is not
      # writable. nothing we can do
      true
  end

  def metadata_matches?(_md, nil), do: true
  def metadata_matches?(_md, []), do: true

  def metadata_matches?(md, [{key, val} | rest]) do
    case Keyword.fetch(md, key) do
      {:ok, ^val} ->
        metadata_matches?(md, rest)

      _ ->
        false
    end
  end

  def maybe_parse_msg(msg) do
    {:ok, data} = Code.string_to_quoted(msg)

    if Keyword.keyword?(data),
      do: data,
      else: msg
  rescue
    _ -> msg
  end

  defp take_metadata(metadata, :all), do: metadata

  defp take_metadata(metadata, keys) do
    Enum.reduce(keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} ->
          [{key, val} | acc]

        :error ->
          acc
      end
    end)
    |> Enum.reverse()
  end

  defp min_level_met?(_level, nil), do: true
  defp min_level_met?(level, min), do: Logger.compare_levels(level, min) != :lt

  defp configure(name, opts) do
    state = %{
      name: nil,
      table: nil,
      io_device: nil,
      inode: nil,
      level: nil,
      metadata: nil,
      metadata_filter: nil,
      store_keywords: false
    }

    configure(name, opts, state)
  end

  defp configure(name, opts, state) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)

    Application.put_env(:logger, name, opts)

    %{
      state
      | name: name,
        table: Keyword.get(opts, :table),
        level: Keyword.get(opts, :level),
        metadata: Keyword.get(opts, :metadata, []),
        metadata_filter: Keyword.get(opts, :metadata_filter),
        store_keywords: Keyword.get(opts, :store_keywords, false)
    }
  end
end
