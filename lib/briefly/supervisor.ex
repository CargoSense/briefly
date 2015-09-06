defmodule Briefly.Supervisor do
  @moduledoc false

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    import Supervisor.Spec

    children = [
      worker(Briefly.Entry, [])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
