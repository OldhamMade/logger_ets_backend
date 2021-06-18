defmodule LoggerEtsBackendTest do
  use ExUnit.Case, async: false
  require Logger

  import LoggerEtsBackend, only: [metadata_matches?: 2]

  @backend {LoggerEtsBackend, :test}
  @name :table_test

  Logger.add_backend(@backend)

  setup_all do
    :ets.new(@name, [:ordered_set, :public, :named_table])
    config(level: :debug)
  end

  describe "error handling during setup" do
    test "does not crash if table does not exist" do
      config(table: nil)

      Logger.debug("foo")
      assert {:error, :already_present} = Logger.add_backend(@backend)
    end
  end

  describe "basic setup" do
    setup do
      config(
        table: @name,
        level: :debug,
        metadata: [],
        metadata_filter: nil
      )

      on_exit(fn ->
        :ets.delete_all_objects(@name)
      end)
    end

    test "can add log entry" do
      Logger.info("simple message")
      # to ensure messages are written to ets
      Logger.flush()

      assert ets_size() == 1
    end

    test "can log utf8 chars" do
      Logger.info("ß\uFFaa\u0222")
      # to ensure messages are written to ets
      Logger.flush()

      {_ts, _level, msg, _md} = log()
      assert ets_size() == 1
      assert msg =~ "ßﾪȢ"
    end

    test "can configure level" do
      config(level: :info)

      Logger.debug("hello")
      assert ets_size() == 0
    end

    test "can configure metadata_filter to capture" do
      config(metadata_filter: [capture: true])

      Logger.debug("should be skipped", capture: false)
      # to ensure messages are written to ets
      Logger.flush()
      assert ets_size() == 0

      Logger.debug("should be logged", capture: true)
      # to ensure messages are written to ets
      Logger.flush()
      assert ets_size() == 1
    end

    test "can configure metadata" do
      config(metadata: [:user_id, :auth])

      Logger.metadata(auth: true)
      Logger.metadata(user_id: 11)
      Logger.metadata(user_id: 13)

      Logger.debug("hello")
      # to ensure messages are written to ets
      Logger.flush()

      {_ts, _level, msg, md} = log()

      assert msg == "hello"
      assert md |> Keyword.fetch!(:auth) == true
      assert md |> Keyword.fetch!(:user_id) == 13
    end

    test "allows `:all` metadata" do
      config(metadata: [])
      Logger.debug("metadata", metadata1: "foo", metadata2: "bar")
      Logger.flush()
      {_ts, _level, _msg, md} = log()
      assert md == []

      config(metadata: [:metadata3])
      Logger.debug("metadata", metadata3: "foo", metadata4: "bar")
      Logger.flush()
      {_ts, _level, _msg, md} = log()
      assert md[:metadata3] == "foo"

      config(metadata: :all)
      Logger.debug("metadata", metadata5: "foo", metadata6: "bar")
      Logger.flush()
      {_ts, _level, _msg, md} = log()
      assert md[:metadata5] == "foo"
      assert md[:metadata6] == "bar"
    end
  end

  describe "metadata_matches?" do
    setup do
      config(
        table: @name,
        level: :debug,
        metadata: [],
        metadata_filter: nil
      )

      on_exit(fn ->
        :ets.delete_all_objects(@name)
      end)
    end

    test "can filter by metadata" do
      # exact match
      assert metadata_matches?([a: 1], a: 1) == true
      # total mismatch
      assert metadata_matches?([b: 1], a: 1) == false
      # default to allow
      assert metadata_matches?([b: 1], nil) == true
      # metadata is superset of filter
      assert metadata_matches?([b: 1, a: 1], a: 1) == true
      # multiple filter keys subset of metadata
      assert metadata_matches?([c: 1, b: 1, a: 1], b: 1, a: 1) == true
      # multiple filter keys superset of metadata
      assert metadata_matches?([a: 1], b: 1, a: 1) == false
    end
  end

  describe "enabling `stored_typed`" do
    setup do
      config(
        table: @name,
        level: :debug,
        metadata: [],
        metadata_filter: nil,
        store_typed: true
      )

      on_exit(fn ->
        :ets.delete_all_objects(@name)
      end)
    end

    test "can store typed data" do
      data = [is_typed: true, ordered: false]

      Logger.debug(data)
      Logger.flush()

      assert {_, :debug, ^data, _} = log()
    end

    test "can store a string message" do
      data = "this is a stringy message"

      Logger.debug(data)
      Logger.flush()

      assert {_, :debug, ^data, _} = log()
    end
  end

  ## private methods

  defp config(opts) do
    Logger.configure_backend(@backend, opts)
    # let the logging process catch-up
    Process.sleep(100)
  end

  defp ets_size() do
    :ets.info(@name) |> Keyword.fetch!(:size)
  end

  defp log() do
    key = :ets.last(@name)

    case :ets.lookup(@name, key) do
      [val] -> val
      [] -> nil
    end
  end
end
