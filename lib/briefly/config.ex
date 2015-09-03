defmodule Briefly.Config do
  @moduledoc false

  @default_directory [{:system, "TMPDIR"}, {:system, "TMP"}, {:system, "TEMP"}, "/tmp"]

  def directory do
    get(:directory)
    |> List.wrap
    |> Enum.find_value(&runtime_value/1)
  end

  defp get(key) do
    Application.get_env(:briefly, key, Keyword.get(defaults, key))
  end

  defp defaults do
    [{:directory, @default_directory}]
  end

  defp runtime_value({:system, env_key}) do
    System.get_env(env_key)
  end
  defp runtime_value(value), do: value

end
