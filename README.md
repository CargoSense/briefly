# Briefly

[![Build Status](https://github.com/CargoSense/briefly/actions/workflows/main.yml/badge.svg)](https://github.com/CargoSense/briefly/actions/workflows/main.yml)
[![Module Version](https://img.shields.io/hexpm/v/briefly.svg)](https://hex.pm/packages/briefly)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/briefly/)
[![Total Download](https://img.shields.io/hexpm/dt/briefly.svg)](https://hex.pm/packages/briefly)
[![License](https://img.shields.io/hexpm/l/briefly.svg)](https://github.com/CargoSense/briefly/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/CargoSense/briefly.svg)](https://github.com/CargoSense/briefly/commits/master)

<!-- MDOC -->

Simple, robust temporary file support for Elixir.

## Highlighted Features

* Create temporary files with prefix and extname options.
* Files are removed after the requesting process exits.
* File creation is based on [Plug.Upload](http://hexdocs.pm/plug/Plug.Upload.html)'s robust retry logic.
* Configurable; built-in support for system environment variables and fallbacks.

## Usage

The fastest way to use Briefly is with [`Mix.install/2`](https://hexdocs.pm/mix/Mix.html#install/2) (requires Elixir v1.12+):

```elixir
Mix.install([
  {:briefly, "~> 0.4.0"}
])

{:ok, path} = Briefly.create()
File.write!(path, "My temp file contents")
File.read!(path)
# => "My temp file contents"

# When this process exits, the file at `path` is removed
```

If you want to use Briefly in a Mix project, you can add the above dependency to your list of dependencies in `mix.exs`.

Briefly can also create a temporary directory:


```elixir
{:ok, dir} = Briefly.create(directory: true)
File.write!(Path.join(dir, "test.txt"), "Some Text")
# When this process exits, the directory and file are removed
```

Refer to [the documentation](http://hexdocs.pm/briefly/Briefly.html#create/1) for a list of options that are available to `Briefly.create/1` and `Briefly.create!/1`.

## Configuration

The default, out-of-the-box settings for Briefly are equivalent to the
following Mix config:

```elixir
# config/config.exs
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

<!-- MDOC -->

## License

Copyright (c) 2023 CargoSense, Inc.

Portions derived from Plug, https://github.com/elixir-lang/plug
Copyright (c) 2013 Plataformatec

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  > http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
