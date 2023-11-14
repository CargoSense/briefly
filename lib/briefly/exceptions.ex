defmodule Briefly.NoRootDirectoryError do
  @moduledoc """
  Returned when none of the root temporary directories could be accessed.
  """
  @type t :: %__MODULE__{
          :tmp_dirs => [String.t()]
        }
  defexception [:tmp_dirs]

  @impl true
  def message(_) do
    "could not create a directory to store temporary files." <>
      " Set the :briefly :directory application setting to a directory with write permission"
  end
end

defmodule Briefly.WriteError do
  @moduledoc """
  Returned when a temporary file cannot be written.
  """
  @type t :: %__MODULE__{
          :code => :file.posix() | :badarg | :terminated | :system_limit,
          :entry_type => :directory | :file,
          :tmp_dir => String.t()
        }
  defexception [:code, :entry_type, :tmp_dir]

  @impl true
  def message(%{code: code} = e) when code in [:eexist, :eacces] do
    "tried to create a temporary #{e.entry_type} in #{e.tmp_dir} but failed." <>
      " Set the :briefly :directory application setting to a directory with write permission"
  end

  @impl true
  def message(e) do
    "could not write #{e.entry_type} in #{e.tmp_dir}, got: #{inspect(e.code)}"
  end
end
