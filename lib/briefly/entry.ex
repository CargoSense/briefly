defmodule Briefly.Entry do
  @moduledoc false

  @dir_table __MODULE__.Dir
  @path_table __MODULE__.Path
  @max_attempts 10

  def server do
    Process.whereis(__MODULE__) ||
      raise "could not find process Briefly.Entry. Have you started the :briefly application?"
  end

  use GenServer

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc false
  # todo: remove deprecation warning on v0.6.0.
  def create(%{monitor_pid: pid} = options) do
    IO.warn("the :monitor_pid option is deprecated, please use Briefly.give_away/3 instead.")

    case create(Map.delete(options, :monitor_pid)) do
      {:ok, path} ->
        :ok = give_away(path, pid, self())
        {:ok, path}

      {:ok, path, io_pid} ->
        :ok = give_away(path, pid, self())
        {:ok, path, io_pid}
    end
  end

  def create(%{} = options) do
    with {:ok, tmp} <- ensure_tmp() do
      open(options, tmp, 0, nil)
    end
  end

  @doc false
  def cleanup(pid) do
    case :ets.lookup(@dir_table, pid) do
      [{^pid, tmp}] ->
        path_entries = :ets.lookup(@path_table, pid)

        secondaries =
          Enum.reduce(
            path_entries,
            MapSet.new(),
            fn path_entry = {_pid, path_value}, seen ->
              delete_path(path_entry)
              if path_value.original_owner != pid do
                MapSet.put(seen, %{path_value | path: nil})
              else
                seen
              end
            end
          )

        File.rmdir(tmp)

        Enum.each(secondaries, fn %{original_owner: owner_pid, root_dir: dir} ->
          if !pid_registered?(owner_pid) do
            File.rmdir(dir)
          end
        end)

        :ets.delete(@path_table, pid)
        :ets.delete(@dir_table, pid)
        for {_pid, path} <- path_entries, do: path

      [] ->
        []
    end
  end

  @doc false
  def give_away(path, to_pid, from_pid)
      when is_binary(path) and is_pid(to_pid) and is_pid(from_pid) do
    with true <- pid_registered?(from_pid),
         path_entry when not is_nil(path_entry) <- path_entry_if_owner(from_pid, path) do
      if pid_registered?(to_pid) do
        :ets.insert(@path_table, {to_pid, path_entry})
        :ets.delete_object(@path_table, {from_pid, path_entry})
        :ok
      else
        server = server()

        {:ok, tmps} = GenServer.call(server, :roots)
        {:ok, tmp} = generate_tmp_dir(tmps)
        :ok = GenServer.call(server, {:give_away, to_pid, tmp, path_entry})

        :ets.delete_object(@path_table, {from_pid, path_entry})

        :ok
      end
    else
      _ ->
        {:error, :unknown_path}
    end
  end

  ## Callbacks
  @impl true
  def init(_init_arg) do
    Process.flag(:trap_exit, true)
    tmp = Briefly.Config.directory()
    cwd = Path.join(File.cwd!(), "tmp")
    :ets.new(@dir_table, [:named_table, :public, :set])
    :ets.new(@path_table, [:named_table, :public, :duplicate_bag])
    {:ok, [tmp, cwd]}
  end

  @impl true
  def handle_call({:monitor, pid}, _from, dirs) do
    Process.monitor(pid)
    {:reply, {:ok, dirs}, dirs}
  end

  def handle_call(:roots, _from, dirs) do
    {:reply, {:ok, dirs}, dirs}
  end

  def handle_call({:give_away, pid, tmp, path_entry}, _from, dirs) do
    # Since we are writing on behalf of another process, we need to make sure
    # the monitor and writing to the tables happen within the same operation.
    Process.monitor(pid)
    :ets.insert_new(@dir_table, {pid, tmp})
    :ets.insert(@path_table, {pid, path_entry})

    {:reply, :ok, dirs}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    cleanup(pid)
    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, _state) do
    folder = fn entry, :ok -> delete_path(entry) end
    :ets.foldl(folder, :ok, @path_table)

    dir_folder = fn {_key, dir}, :ok ->
      case File.rmdir(dir) do
        :ok -> :ok
        {:error, :eexist} -> :ok
        {:error, :enoent} -> :ok
        {:error, :enotdir} -> :ok
      end
    end

    :ets.foldl(dir_folder, :ok, @dir_table)
  end

  ## Helpers

  defp ensure_tmp() do
    pid = self()

    case :ets.lookup(@dir_table, pid) do
      [{^pid, tmp}] ->
        {:ok, tmp}

      [] ->
        server = server()
        {:ok, tmps} = GenServer.call(server, {:monitor, pid})

        with {:ok, tmp} <- generate_tmp_dir(tmps) do
          true = :ets.insert_new(@dir_table, {pid, tmp})
          {:ok, tmp}
        end
    end
  end

  defp generate_tmp_dir(tmp_roots) do
    subdir = path(%{prefix: "briefly-", extname: ""})

    if tmp = Enum.find_value(tmp_roots, &write_tmp_dir({&1, subdir})) do
      {:ok, tmp}
    else
      {:error, %Briefly.NoRootDirectoryError{tmp_dirs: tmp_roots}}
    end
  end

  defp write_tmp_dir({root, path}) do
    fullpath = Path.join(root, path)

    case File.mkdir_p(root) do
      {:error, _} ->
        nil

      :ok ->
        case File.mkdir(fullpath) do
          {:error, _} ->
            nil

          :ok ->
            case File.chmod(fullpath, Briefly.Config.directory_mode()) do
              {:error, _} -> nil
              :ok -> fullpath
            end
        end
    end
  end

  defp open(%{type: :directory} = options, tmp, attempts, _) when attempts < @max_attempts do
    path = path(options, tmp)

    case File.mkdir_p(path) do
      :ok ->
        value = %{path: path, root_dir: tmp, original_owner: self()}
        :ets.insert(@path_table, {self(), value})
        {:ok, path}

      {:error, reason} when reason in [:eexist, :eacces] ->
        last_error = %Briefly.WriteError{code: reason, entry_type: :directory, tmp_dir: tmp}
        open(options, tmp, attempts + 1, last_error)

      {:error, code} ->
        {:error, %Briefly.WriteError{code: code, entry_type: :directory, tmp_dir: tmp}}
    end
  end

  defp open(%{type: :device} = options, tmp, attempts, _) when attempts < @max_attempts do
    path = path(options, tmp)

    case File.open(path, [:read, :write, :exclusive]) do
      {:ok, device_pid} ->
        value = %{path: path, root_dir: tmp, original_owner: self()}
        :ets.insert(@path_table, {self(), value})
        {:ok, path, device_pid}

      {:error, reason} when reason in [:eexist, :eacces] ->
        last_error = %Briefly.WriteError{code: reason, entry_type: :file, tmp_dir: tmp}
        open(options, tmp, attempts + 1, last_error)

      {:error, code} ->
        {:error, %Briefly.WriteError{code: code, entry_type: :file, tmp_dir: tmp}}
    end
  end

  defp open(%{directory: true} = options, tmp, attempts, last_error) do
    new_opts = Map.put(options, :type, :directory)
    open(new_opts, tmp, attempts, last_error)
  end

  defp open(options, tmp, attempts, _) when attempts < @max_attempts do
    path = path(options, tmp)

    case :file.write_file(path, "", [:write, :raw, :exclusive, :binary]) do
      :ok ->
        value = %{path: path, root_dir: tmp, original_owner: self()}
        :ets.insert(@path_table, {self(), value})
        {:ok, path}

      {:error, reason} when reason in [:eexist, :eacces] ->
        last_error = %Briefly.WriteError{code: reason, entry_type: :file, tmp_dir: tmp}
        open(options, tmp, attempts + 1, last_error)

      {:error, code} ->
        {:error, %Briefly.WriteError{code: code, entry_type: :file, tmp_dir: tmp}}
    end
  end

  defp open(_options, _tmp, _attempts, last_error) do
    {:error, last_error}
  end

  defp path(options) do
    time = :erlang.monotonic_time() |> to_string |> String.trim("-")

    Enum.join(
      [
        prefix(options),
        time,
        random_padding()
      ],
      "-"
    ) <> extname(options)
  end

  defp path(options, tmp) do
    Path.join([tmp, path(options)])
  end

  defp random_padding(length \\ 20) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
    |> String.replace(~r/[[:punct:]]/, "")
  end

  defp prefix(%{prefix: value}), do: value
  defp prefix(_), do: Briefly.Config.default_prefix()

  defp extname(%{extname: value}), do: value
  defp extname(_), do: Briefly.Config.default_extname()

  defp pid_registered?(pid) do
    :ets.member(@dir_table, pid)
  end

  defp path_entry_if_owner(pid, path) do
    owned_paths = :ets.lookup(@path_table, pid)

    Enum.find_value(owned_paths, fn {_pid, %{path: p} = entry} ->
      if p == path, do: entry
    end)
  end

  defp delete_path({_pid, %{path: path}}) do
    File.rm_rf(path)
    :ok
  end
end
