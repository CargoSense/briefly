Briefly
=======
[![Build Status](https://travis-ci.org/CargoSense/briefly.svg?branch=master)](https://travis-ci.org/CargoSense/briefly)

Temporary files for Elixir.

## Highlighted Features

* Create temporary files using a prefix
* Files are removed after the process that requested the file dies
* File creation is based on [Plug.Upload](http://hexdocs.pm/plug/Plug.Upload.html)'s robust retry logic
* Configurable temporary directory setting with support for fallbacks

## Example

```elixir
{:ok, path} = Briefly.create("myprefix")
File.write!(path, "Some Text")
content = File.read!(path)
# When this process exits, the file at `path` is removed
```

## Configuration

The default, out-of-the-box settings for Briefly are equivalent to the
following Mix config:

```elixir
config :briefly,
  directory: [{:system, "TMPDIR"}, {:system, "TMP"}, {:system, "TEMP"}, "/tmp"]
  ```

`directory` here declares an ordered list of possible directory definitions that Briefly will check in order.

The `{:system, env_var}` tuples point to system environment variables to be checked. If none of these are defined, Briefly will use the final entry: `/tmp`.

You can override the `directory` setting with your own candidates in your application Mix config.

## License

The MIT License (MIT)

Copyright (c) 2015 CargoSense, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
