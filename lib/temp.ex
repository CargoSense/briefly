defmodule Temp do

  use Application

  @doc false
  def start(_type, _args) do
    Temp.Supervisor.start_link()
  end

end
