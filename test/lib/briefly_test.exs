defmodule Test.Briefly.File do
  use ExUnit.Case, async: true

  @fixture "content"

  test "removes the random file on process death" do
    parent = self()

    {pid, ref} = spawn_monitor fn ->
      {:ok, path} = Briefly.create("sample")
      send parent, {:path, path}
      File.write!(path, @fixture)
      assert File.read!(path) == @fixture
    end

    path =
      receive do
      {:path, path} -> path
    after
      1_000 -> flunk "didn't get a path"
    end

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        {:ok, _} = Briefly.create("sample")
        refute File.exists?(path)
    end
  end
end
