defmodule Briefly do
  @moduledoc File.read!("#{__DIR__}/../README.md")

  use Application

  @doc false
  def start(_type, _args) do
    Briefly.Supervisor.start_link()
  end

  @doc """
  Requests a temporary file to be created with the given prefix
  """
  @spec create(binary) ::
  {:ok, binary} |
  {:too_many_attempts, binary, pos_integer} |
  {:no_tmp, [binary]}
  def create(prefix) do
    GenServer.call(Briefly.File.server, {:file, prefix})
  end

  @doc """
  Requests a temporary file to be created with the given prefix
  and raises on failure
  """
  @spec create!(binary) :: binary | no_return
  def create!(prefix) do
    case create(prefix) do
      {:ok, path} ->
        path
      {:too_many_attempts, tmp, attempts} ->
        raise "tried #{attempts} times to create a temporary file at #{tmp} but failed. What gives?"
      {:no_tmp, _tmps} ->
        raise "could not create a tmp directory to store temporary files. Set TMPDIR, TMP, or TEMP to a directory with write permission"
    end
  end

end
