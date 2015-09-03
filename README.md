Briefly
=======
[![Build Status](https://travis-ci.org/CargoSense/briefly.svg?branch=master)](https://travis-ci.org/CargoSense/briefly)

Simple, robust temporary file support for Elixir.

## Highlighted Features

* Create temporary files using a prefix
* Files are removed after the process that requested the file dies
* File creation is based on [Plug.Upload](http://hexdocs.pm/plug/Plug.Upload.html)'s robust retry logic
* Configurable temporary directory setting with support for fallbacks

## Installation

Add as a dependency to your `mix.exs`:

```elixir
def deps do
  [
    briefly: "~> 0.2"
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

```elixir
{:ok, path} = Briefly.create
File.write!(path, "Some Text")
content = File.read!(path)
# When this process exits, the file at `path` is removed
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

The MIT License (MIT)

Copyright (c) 2015 CargoSense, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
