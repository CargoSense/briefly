defmodule Briefly.Entry do
  @moduledoc false

  def server do
    Process.whereis(__MODULE__) ||
      raise "could not find process Briefly.Entry. Have you started the :briefly application?"
  end

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  ## Callbacks

  @max_attempts 10

  def init(:ok) do
    tmp = Briefly.Config.directory
    cwd = Path.join(File.cwd!, "tmp")
    ets = :ets.new(:briefly, [:private])
    {:ok, {[tmp, cwd], ets}}
  end

  def handle_call({:create, opts}, {pid, _ref}, {tmps, ets} = state) do
    options = opts |> Enum.into(%{})
    case find_tmp_dir(pid, tmps, ets) do
      {:ok, tmp, paths} ->
        {:reply, open(options, tmp, 0, pid, ets, paths), state}
      {:no_tmp, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, {_, ets} = state) do
    case :ets.lookup(ets, pid) do
      [{pid, _tmp, paths}] ->
        :ets.delete(ets, pid)
        Enum.each paths, &File.rm_rf/1
      [] ->
        :ok
    end
    {:noreply, state}
  end

  def handle_info(msg, state) do
    super(msg, state)
  end

  ## Helpers

  defp find_tmp_dir(pid, tmps, ets) do
    case :ets.lookup(ets, pid) do
      [{^pid, tmp, paths}] ->
        {:ok, tmp, paths}
      [] ->
        if tmp = ensure_tmp_dir(tmps) do
          :erlang.monitor(:process, pid)
          :ets.insert(ets, {pid, tmp, []})
          {:ok, tmp, []}
        else
          {:no_tmp, tmps}
        end
    end
  end

  defp ensure_tmp_dir(tmps) do
    {mega, _, _} = :os.timestamp
    subdir = "/briefly-" <> i(mega)
    Enum.find_value(tmps, &write_tmp_dir(&1 <> subdir))
  end

  defp write_tmp_dir(path) do
    case File.mkdir_p(path) do
      :ok -> path
      {:error, _} -> nil
    end
  end

  defp open(%{directory: true} = options, tmp, attempts, pid, ets, paths) when attempts < @max_attempts do
    path = path(options, tmp)

    case File.mkdir_p(path) do
      :ok ->
        :ets.update_element(ets, pid, {3, [path|paths]})
        {:ok, path}
      {:error, reason} when reason in [:eexist, :eacces] ->
        open(options, tmp, attempts + 1, pid, ets, paths)
    end
  end

  defp open(options, tmp, attempts, pid, ets, paths) when attempts < @max_attempts do
    path = path(options, tmp)

    case :file.write_file(path, "", [:write, :raw, :exclusive, :binary]) do
      :ok ->
        :ets.update_element(ets, pid, {3, [path|paths]})
        {:ok, path}
      {:error, reason} when reason in [:eexist, :eacces] ->
        open(options, tmp, attempts + 1, pid, ets, paths)
    end
  end

  defp open(_prefix, tmp, attempts, _pid, _ets, _paths) do
    {:too_many_attempts, tmp, attempts}
  end

  @compile {:inline, i: 1}
  defp i(integer), do: Integer.to_string(integer)

  defp path(options, tmp) do
    {_mega, sec, micro} = :os.timestamp
    scheduler_id = :erlang.system_info(:scheduler_id)
    IO.iodata_to_binary([tmp, "/",
                         prefix(options),
                         "-", i(sec), "-", i(micro), "-", i(scheduler_id),
                         extname(options)])
  end

  defp prefix(%{prefix: value}), do: value
  defp prefix(_), do: Briefly.Config.default_prefix

  defp extname(%{extname: value}), do: value
  defp extname(_), do: Briefly.Config.default_extname

end
