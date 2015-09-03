defmodule Briefly do

  use Application

  @doc false
  def start(_type, _args) do
    Briefly.Supervisor.start_link()
  end

end
