defmodule Test.Briefly do
  use ExUnit.Case, async: true

  @prefix "temp"
  @fixture "content"
  @extname ".tst"

  test "removes the random file on process death" do
    parent = self()

    {pid, ref} = spawn_monitor fn ->
      {:ok, path} = Briefly.create
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
        {:ok, _} = Briefly.create
        refute File.exists?(path)
    end
  end

  test "uses the prefix" do
    {_pid, _ref} = spawn_monitor fn ->
      {:ok, path} = Briefly.create(prefix: @prefix)
      assert Path.basename(path) |> String.starts_with?(@prefix <> "-")
    end
  end

  test "uses the extname" do
    {_pid, _ref} = spawn_monitor fn ->
      {:ok, path} = Briefly.create(extname: @extname)
      assert Path.extname(path) == @extname
    end
  end

end
