defmodule Briefly do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(1)

  use Application

  @doc false
  @impl true
  def start(_type, _args) do
    Briefly.Supervisor.start_link()
  end

  @type create_opts :: [
          {:prefix, binary},
          {:extname, binary},
          {:directory, boolean}
        ]

  @doc """
  Requests a temporary file to be created with the given options.
  """
  @spec create(create_opts) ::
          {:ok, binary}
          | {:no_space, binary}
          | {:too_many_attempts, binary, pos_integer}
          | {:no_tmp, [binary]}
  def create(opts \\ []) do
    opts
    |> Enum.into(%{})
    |> Briefly.Entry.create()
  end

  @doc """
  Requests a temporary file to be created with the given options
  and raises on failure.
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

  @doc """
  Removes the temporary files and directories created by the process and returns their paths.
  """
  @spec cleanup(pid) :: [binary]
  def cleanup(pid \\ self()) do
    Briefly.Entry.cleanup(pid)
  end

  @doc """
  Assign ownership of the given tmp file to another process.
  """
  @spec give_away(binary, pid, pid) :: :ok | {:error, :unknown_path}
  def give_away(path, to_pid, from_pid \\ self())

  def give_away(path, to_pid, from_pid) do
    Briefly.Entry.give_away(path, to_pid, from_pid)
  end
end
