defmodule LoggerEtsBackend do
  @moduledoc false

  @behaviour :gen_event

  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  def handle_call({:configure, opts}, %{name: name} = state) do
    {:ok, :ok, configure(name, opts, state)}
  end

  def handle_event(
    {level, _gl, {Logger, msg, ts, md}},
    %{level: min_level, metadata_filter: metadata_filter} = state
  ) do
    if (is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt)
    and metadata_matches?(md, metadata_filter) do
      log_event(level, msg, ts, md, state)
    end
    {:ok, state}
  end

  def handle_event(:flush, state) do
    # We're not buffering anything so this is a no-op
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  defp log_event(level, msg, ts, md, %{table: table, metadata: md_keys} = _state) do
    try do
      filtered_md = take_metadata(md, md_keys)
      :ets.insert_new(table, {ts, level, msg, filtered_md})
    rescue
      ErlangError ->
        # table doesn't exist or is not
        # writable. nothing we can do
        true
    end
  end

  def metadata_matches?(_md, nil), do: true
  def metadata_matches?(_md, []), do: true # all of the filter keys are present
  def metadata_matches?(md, [{key, val} | rest]) do
    case Keyword.fetch(md, key) do
      {:ok, ^val} ->
        metadata_matches?(md, rest)
      _ -> false #fail on first mismatch
    end
  end

  defp take_metadata(metadata, :all), do: metadata
  defp take_metadata(metadata, keys) do
    metadatas = Enum.reduce(keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} ->
          [{key, val} | acc]
        :error ->
          acc
      end
    end)

    Enum.reverse(metadatas)
  end

  defp configure(name, opts) do
    state = %{
      name: nil,
      table: nil,
      io_device: nil,
      inode: nil,
      level: nil,
      metadata: nil,
      metadata_filter: nil
    }
    configure(name, opts, state)
  end

  defp configure(name, opts, state) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    table = Keyword.get(opts, :table)
    level = Keyword.get(opts, :level)
    metadata = Keyword.get(opts, :metadata, []) #
    metadata_filter = Keyword.get(opts, :metadata_filter)

    %{ state |
       name: name,
       table: table,
       level: level,
       metadata: metadata,
       metadata_filter: metadata_filter
    }
  end
end
