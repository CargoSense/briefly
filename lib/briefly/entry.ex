defmodule Briefly.Entry do
  @moduledoc false

  @table __MODULE__
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
  def create(%{} = options) do
    case find_tmp_dir(options) do
      {:ok, pid, tmp, paths} ->
        open(options, tmp, 0, pid, paths)

      {:no_tmp, _} = error ->
        error
    end
  end

  @doc false
  def cleanup(pid) do
    case :ets.lookup(@table, pid) do
      [{^pid, _tmp, paths}] ->
        :ets.delete(@table, pid)
        Enum.each(paths, &File.rm_rf/1)
        paths

      [] ->
        []
    end
  end

  ## Callbacks
  @impl true
  def init(_init_arg) do
    tmp = Briefly.Config.directory()
    cwd = Path.join(File.cwd!(), "tmp")
    :ets.new(@table, [:named_table, :public, :set])
    {:ok, [tmp, cwd]}
  end

  @impl true
  def handle_call({:briefly, pid}, _, dirs) do
    Process.monitor(pid)
    {:reply, {:ok, dirs}, dirs}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    cleanup(pid)
    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  ## Helpers

  defp find_tmp_dir(options) do
    pid = monitor_pid(options, self())
    server = server()

    case :ets.lookup(@table, pid) do
      [{^pid, tmp, paths}] ->
        {:ok, pid, tmp, paths}

      [] ->
        {:ok, tmps} = GenServer.call(server, {:briefly, pid})

        if tmp = ensure_tmp_dir(tmps) do
          true = :ets.insert_new(@table, {pid, tmp, []})
          {:ok, pid, tmp, []}
        else
          {:no_tmp, tmps}
        end
    end
  end

  defp ensure_tmp_dir(tmps) do
    {mega, _, _} = :os.timestamp()
    subdir = "briefly-#{mega}"
    Enum.find_value(tmps, &write_tmp_dir(Path.join(&1, subdir)))
  end

  defp write_tmp_dir(path) do
    case File.mkdir_p(path) do
      :ok -> path
      {:error, _} -> nil
    end
  end

  defp open(%{directory: true} = options, tmp, attempts, pid, paths)
       when attempts < @max_attempts do
    path = path(options, tmp)

    case File.mkdir_p(path) do
      :ok ->
        :ets.update_element(@table, pid, {3, [path | paths]})
        {:ok, path}

      {:error, reason} when reason in [:eexist, :eacces] ->
        open(options, tmp, attempts + 1, pid, paths)
    end
  end

  defp open(options, tmp, attempts, pid, paths) when attempts < @max_attempts do
    path = path(options, tmp)

    case :file.write_file(path, "", [:write, :raw, :exclusive, :binary]) do
      :ok ->
        :ets.update_element(@table, pid, {3, [path | paths]})
        {:ok, path}

      {:error, reason} when reason in [:eexist, :eacces] ->
        open(options, tmp, attempts + 1, pid, paths)
    end
  end

  defp open(_prefix, tmp, attempts, _pid, _paths) do
    {:too_many_attempts, tmp, attempts}
  end

  defp path(options, tmp) do
    time = :erlang.monotonic_time() |> to_string |> String.trim("-")

    folder =
      Enum.join(
        [
          prefix(options),
          time,
          random_padding()
        ],
        "-"
      ) <> extname(options)

    Path.join([tmp, folder])
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

  defp monitor_pid(%{monitor_pid: pid}, _), do: pid
  defp monitor_pid(_options, pid), do: pid
end
