defmodule Briefly.Config do
  @moduledoc false

  def directory do
    get(:directory)
  end

  def default_prefix do
    get(:default_prefix)
  end

  def default_extname do
    get(:default_extname)
  end

  defp get(key) do
    Application.get_env(:briefly, key, [])
    |> List.wrap
    |> Enum.find_value(&runtime_value/1)
  end

  defp runtime_value({:system, env_key}) do
    System.get_env(env_key)
  end
  defp runtime_value(value), do: value

end
