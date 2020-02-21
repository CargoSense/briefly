defmodule Test.Briefly do
  use ExUnit.Case, async: true

  @prefix "temp"
  @fixture "content"
  @extname ".tst"

  test "removes the random file on process death" do
    parent = self()

    {pid, ref} =
      spawn_monitor(fn ->
        {:ok, path} = Briefly.create()
        send(parent, {:path, path})
        File.write!(path, @fixture)
        assert File.read!(path) == @fixture
      end)

    path =
      receive do
        {:path, path} -> path
      after
        1_000 -> flunk("didn't get a path")
      end

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        {:ok, _} = Briefly.create()
        refute File.exists?(path)
    end
  end

  test "allows specifying different pid for monitoring" do
    parent = self()

    {monitor_pid, monitor_ref} =
      spawn_monitor(fn ->
        receive do
          :shutdown -> :ok
        end
      end)

    {pid, ref} =
      spawn_monitor(fn ->
        {:ok, path} = Briefly.create(monitor_pid: monitor_pid)
        send(parent, {:path, path})
        File.write!(path, @fixture)
        assert File.read!(path) == @fixture
      end)

    path =
      receive do
        {:path, path} -> path
      after
        1_000 -> flunk("didn't get a path")
      end

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        # {:ok, _} = Briefly.create()
        assert File.exists?(path)

        send(monitor_pid, :shutdown)
        receive do
          {:DOWN, ^monitor_ref, :process, ^monitor_pid, :normal} ->
            {:ok, _} = Briefly.create()
            refute File.exists?(path)
        end
    end
  end

  test "allows removing files attached to current process" do
    parent = self()

    {pid, _ref} =
      spawn_monitor(fn ->
        {:ok, path} = Briefly.create()

        receive do
          :cleanup ->
            Briefly.cleanup()
            send(parent, {:cleanup, path})
        end

        receive do
          :terminate -> :ok
        end
      end)

    send(pid, :cleanup)

    receive do
      {:cleanup, path} ->
        refute File.exists?(path)
        send(pid, :terminate)
    after
      1_000 -> flunk("didn't get a path")
    end
  end

  test "uses the prefix" do
    {_pid, _ref} =
      spawn_monitor(fn ->
        {:ok, path} = Briefly.create(prefix: @prefix)
        assert Path.basename(path) |> String.starts_with?(@prefix <> "-")
      end)
  end

  test "uses the extname" do
    {_pid, _ref} =
      spawn_monitor(fn ->
        {:ok, path} = Briefly.create(extname: @extname)
        assert Path.extname(path) == @extname
      end)
  end

  test "can create and remove a directory" do
    parent = self()

    {pid, ref} =
      spawn_monitor(fn ->
        {:ok, path} = Briefly.create(directory: true)
        send(parent, {:path, path})
        assert File.stat!(path).type == :directory
        File.write!(Path.join(path, "a-file"), "some content")
      end)

    path =
      receive do
        {:path, path} -> path
      after
        1_000 -> flunk("didn't get a path")
      end

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        # Give the rm_rf a chance to finish
        :timer.sleep(1000)
        refute File.exists?(path)
    end
  end
end
