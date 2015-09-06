Briefly
=======
[![Build Status](https://travis-ci.org/CargoSense/briefly.svg?branch=master)](https://travis-ci.org/CargoSense/briefly)

Simple, robust temporary file support for Elixir.

## Highlighted Features

* Create temporary files with prefix and extname options
* Files are removed after the process that requested the file dies
* File creation is based on [Plug.Upload](http://hexdocs.pm/plug/Plug.Upload.html)'s robust retry logic
* Configurable; built-in support for system environment variables and fallbacks

## Installation

Add as a dependency to your `mix.exs`:

```elixir
def deps do
  [
    briefly: "~> 0.3"
  ]
end
```

Install it with `mix deps.get` and don't forget to add it to your applications list:

```elixir
def application do
  [applications: [:briefly]]
end
```

## Example

Create a file:

```elixir
{:ok, path} = Briefly.create
File.write!(path, "Some Text")
content = File.read!(path)
# When this process exits, the file at `path` is removed
```

Create a directory:

```elixir
{:ok, path} = Briefly.create(directory: true)
File.write!(Path.join(path, "test.txt"), "Some Text")
# When this process exits, the directory and file are removed
```

See [the documentation](http://hexdocs.pm/briefly/Briefly.html#create/1) to see
the options that available to `Briefly.create/1` and `Briefly.create!/1`.

## Configuration

The default, out-of-the-box settings for Briefly are equivalent to the
following Mix config:

```elixir
config :briefly,
  directory: [{:system, "TMPDIR"}, {:system, "TMP"}, {:system, "TEMP"}, "/tmp"],
  default_prefix: "briefly",
  default_extname: ""
  ```

`directory` here declares an ordered list of possible directory definitions that Briefly will check in order.

The `{:system, env_var}` tuples point to system environment variables to be checked. If none of these are defined, Briefly will use the final entry: `/tmp`.

You can override the settings with your own candidates in your application Mix
config (and pass `prefix` and `extname` to `Briefly.create` to override
`default_prefix` and `default_extname` on a case-by-case basis).

## License

See [LICENSE](./LICENSE).
