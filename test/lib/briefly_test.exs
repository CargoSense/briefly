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
        assert ExUnit.CaptureIO.capture_io(:stderr, fn ->
                 {:ok, path} = Briefly.create(monitor_pid: monitor_pid)
                 send(parent, {:path, path})
                 File.write!(path, @fixture)
                 assert File.read!(path) == @fixture
               end) =~ "the :monitor_pid option is deprecated"
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
        assert File.exists?(path)

        send(monitor_pid, :shutdown)

        receive do
          {:DOWN, ^monitor_ref, :process, ^monitor_pid, :normal} ->
            {:ok, _} = Briefly.create()
            cleanup_wait_loop(monitor_pid)
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
            assert [_] = Briefly.cleanup()
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

  test "can create and remove a directory with the deprecated boolean option" do
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

  test "can create and remove a directory with the type: :directory option" do
    parent = self()

    {pid, ref} =
      spawn_monitor(fn ->
        {:ok, path} = Briefly.create(type: :directory)
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

  test "terminate removes all files" do
    {:ok, path} = Briefly.create()
    :ok = Briefly.Entry.terminate(:shutdown, [])
    refute File.exists?(path)
  end

  describe "give_away/3" do
    test "assigns ownership to other pid" do
      parent = self()

      {other_pid, other_ref} =
        spawn_monitor(fn ->
          receive do
            :exit -> nil
          end
        end)

      {pid, ref} =
        spawn_monitor(fn ->
          {:ok, path1} = Briefly.create()
          send(parent, {:path1, path1})
          File.open!(path1)

          {:ok, path2} = Briefly.create()
          send(parent, {:path2, path2})
          File.open!(path2)

          {:ok, path3} = Briefly.create()
          send(parent, {:path3, path3})
          File.open!(path3)

          :ok = Briefly.give_away(path1, other_pid)
          :ok = Briefly.give_away(path2, other_pid)
        end)

      path1 =
        receive do
          {:path1, path} -> path
        after
          1_000 -> flunk("didn't get a path")
        end

      path2 =
        receive do
          {:path2, path} -> path
        after
          1_000 -> flunk("didn't get a path")
        end

      path3 =
        receive do
          {:path3, path} -> path
        after
          1_000 -> flunk("didn't get a path")
        end

      receive do
        {:DOWN, ^ref, :process, ^pid, :normal} ->
          {:ok, _} = Briefly.create()

          assert File.exists?(path1)
          assert File.exists?(path2)
          refute File.exists?(path3)
      end

      send(other_pid, :exit)

      receive do
        {:DOWN, ^other_ref, :process, ^other_pid, :normal} ->
          # force sync by creating file in unknown process
          parent = self()

          spawn(fn ->
            {:ok, _} = Briefly.create()
            send(parent, :continue)
          end)

          receive do
            :continue -> :ok
          end

          refute File.exists?(path1)
          refute File.exists?(path2)
      end
    end

    test "assigns ownership to other pid which has existing paths" do
      parent = self()

      {other_pid, other_ref} =
        spawn_monitor(fn ->
          {:ok, path} = Briefly.create()
          send(parent, {:recipient, path})

          receive do
            :exit -> nil
          end
        end)

      path =
        receive do
          {:recipient, path} -> path
        after
          1_000 -> flunk("didn't get a path")
        end

      {pid, ref} =
        spawn_monitor(fn ->
          {:ok, path1} = Briefly.create()
          send(parent, {:path1, path1})
          File.open!(path1)

          :ok = Briefly.give_away(path1, other_pid)
        end)

      path1 =
        receive do
          {:path1, path} -> path
        after
          1_000 -> flunk("didn't get a path")
        end

      receive do
        {:DOWN, ^ref, :process, ^pid, :normal} ->
          {:ok, _} = Briefly.create()

          assert File.exists?(path)
          assert File.exists?(path1)
      end

      send(other_pid, :exit)

      receive do
        {:DOWN, ^other_ref, :process, ^other_pid, :normal} ->
          # force sync by creating file in unknown process
          parent = self()

          spawn(fn ->
            {:ok, _} = Briefly.create()
            send(parent, :continue)
          end)

          receive do
            :continue -> :ok
          end

          refute File.exists?(path)
          refute File.exists?(path1)
      end
    end

    test "cleans up gifted temporary directories when appropriate" do
      parent = self()

      {receive1_pid, receive1_ref} =
        spawn_monitor(fn ->
          receive do
            :exit -> nil
          end
        end)

      {receive2_pid, receive2_ref} =
        spawn_monitor(fn ->
          receive do
            :exit -> nil
          end
        end)

      {give_pid, give_ref} =
        spawn_monitor(fn ->
          {:ok, path1} = Briefly.create()
          send(parent, {:path1, path1})
          File.open!(path1)

          {:ok, path2} = Briefly.create()
          send(parent, {:path2, path2})
          File.open!(path2)

          :ok = Briefly.give_away(path1, receive1_pid)
          :ok = Briefly.give_away(path2, receive1_pid)

          send(parent, :given_away)

          receive do
            :continue -> :ok
          end

          {:ok, path3} = Briefly.create()
          send(parent, {:path3, path3})
          File.open!(path3)

          :ok = Briefly.give_away(path3, receive2_pid)
        end)

      path1 =
        receive do
          {:path1, path} -> path
        after
          1_000 -> flunk("didn't get a path")
        end

      path2 =
        receive do
          {:path2, path} -> path
        after
          1_000 -> flunk("didn't get a path")
        end

      receive do
        :given_away -> nil
      after
        1_000 -> flunk("didn't get signal for given_away")
      end

      send(receive1_pid, :exit)

      receive do
        {:DOWN, ^receive1_ref, :process, ^receive1_pid, :normal} ->
          # force sync by creating file in unknown process
          parent = self()

          spawn(fn ->
            {:ok, _} = Briefly.create()
            send(parent, :continue)
          end)

          receive do
            :continue -> :ok
          end

          cleanup_wait_loop(receive1_pid)

          refute File.exists?(path1)
          refute File.exists?(path2)
          assert File.exists?(Path.dirname(path1))
      end

      send(give_pid, :continue)

      path3 =
        receive do
          {:path3, path} -> path
        after
          1_000 -> flunk("didn't get a path")
        end

      receive do
        {:DOWN, ^give_ref, :process, ^give_pid, :normal} ->
          {:ok, _} = Briefly.create()

          assert File.exists?(path3)
      end

      send(receive2_pid, :exit)

      receive do
        {:DOWN, ^receive2_ref, :process, ^receive2_pid, :normal} ->
          # force sync by creating file in unknown process
          parent = self()

          spawn(fn ->
            {:ok, _} = Briefly.create()
            send(parent, :continue)
          end)

          receive do
            :continue -> :ok
          end

          cleanup_wait_loop(receive2_pid)

          refute File.exists?(path3)
          refute File.exists?(Path.dirname(path3))
      end
    end
  end

  test "returns an io device if device is requested" do
    parent = self()

    {pid, ref} =
      spawn_monitor(fn ->
        {:ok, path1, device1} = Briefly.create(%{type: :device})
        IO.write(device1, @fixture)
        assert File.read!(path1) == @fixture
        {:ok, path2, device2} = Briefly.create(%{type: :device})
        File.write!(path2, @fixture)
        assert IO.read(device2, 1024) == @fixture
        send(parent, {:paths_and_devices, [path1, path2], [device1, device2]})
      end)

    {paths, devices} =
      receive do
        {:paths_and_devices, paths, devices} -> {paths, devices}
      after
        1_000 -> flunk("didn't get paths")
      end

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        {:ok, _} = Briefly.create()

        Enum.each(paths, fn path ->
          refute File.exists?(path)
        end)

        Enum.each(devices, fn device ->
          refute Process.info(device)
        end)
    end
  end

  # There is no synchronization between cleanup and other monitors, so there
  # is a race condition where the cleanup may not have happened yet. Use ets
  # as a signal that the test can use to busy wait. More likely to occur with
  # debugging prints or intentional delays
  defp cleanup_wait_loop(pid) do
     if :ets.member(Briefly.Entry.Dir, pid) do
       Process.sleep(100)
       cleanup_wait_loop(pid)
     end
  end
end
