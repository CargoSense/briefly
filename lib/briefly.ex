defmodule Briefly do
  @moduledoc File.read!("#{__DIR__}/../README.md")

  use Application

  @doc false
  def start(_type, _args) do
    Briefly.Supervisor.start_link()
  end

  @type create_opts :: [
    {:prefix, binary},
    {:extname, binary},
    {:directory, boolean}
  ]

  @doc """
  Requests a temporary file to be created with the given options
  """
  @spec create(create_opts) ::
    {:ok, binary} |
    {:too_many_attempts, binary, pos_integer} |
    {:no_tmp, [binary]}
  def create(opts \\ []) do
    GenServer.call(Briefly.Entry.server, {:create, opts})
  end

  @doc """
  Requests a temporary file to be created with the given options
  and raises on failure
  """
  @spec create!(create_opts) :: binary | no_return
  def create!(opts \\ []) do
    case create(opts) do
      {:ok, path} ->
        path
      {:too_many_attempts, tmp, attempts} ->
        raise "tried #{attempts} times to create a temporary file at #{tmp} but failed. What gives?"
      {:no_tmp, _tmps} ->
        raise "could not create a tmp directory to store temporary files. Set the :briefly :directory application setting to a directory with write permission"
    end
  end

end
