# Changelog

## v0.5.1 (2024-01-19)

- Introduces `Briefly.create(type: :device)` to return a raw IO device. https://github.com/CargoSense/briefly/pull/43. `create(directory: true)` is deprecated in favor of `create(type: :directory)`.


## v0.5.0 (2023-11-15)

This version changes the Briefly API, so read the notes below and upgrade with care.

- Change the return value of `Briefly.create/1` to be either `{:ok, path}` or
  `{:error, Exception.t()}`. The following exceptions may be returned:

  - `%Briefly.NoRootDirectoryError{}` - Briefly is unable to create a root temporary
    directory. The exception contains the temp dirs attempted.

  - `%Briefly.WriteError{}` - A temporary entry cannot be created. The exception
    contains the POSIX error code the caused the failure.

For example, if you have this:

```elixir
case Briefly.create() do
  {:ok, path} -> path
  {:no_space, _} -> raise "no space"
  {:too_many_attempts, _} -> raise "too many attempts"
  {:no_tmp, _} -> raise "no tmp dirs"
end
```

...then change it to this:

```elixir
case Briefly.create() do
  {:ok, path} -> path
  {:error, %Briefly.WriteError{code: :enospc}} -> raise "no space"
  {:error, %Briefly.WriteError{code: c}} when c in [:eexist, :eacces] -> raise "too many attempts"
  {:error, %Briefly.NoRootDirectoryError{}} -> raise "no tmp dirs"
  {:error, exception} when is_exception(exception) -> raise exception
end
```

- Add `Briefly.give_away/3` to transfer ownership of a tmp file.
- Deprecate the `:monitor_pid` option.

If you were previously using `:monitor_pid` like this:

```elixir
{:ok, path} = Briefly.create(monitor_pid: pid)
```

...then change it to this:

```elixir
{:ok, path} = Briefly.create()
:ok = Briefly.give_away(path, pid)
```

## v0.4.1 (2023-01-11)

- Fix an issue with custom tmp dirs without a trailing slash ([#24](https://github.com/CargoSense/briefly/pull/24)) @srgpqt

## v0.4.0 (2023-01-09)

**Note Briefly v0.4+ requires Elixir v1.11+.**

- Add `:monitor_pid` option to `Briefly.create/1` ([#19](https://github.com/CargoSense/briefly/pull/19)) @scarfacedeb
- Avoid folder naming conflicts with monotonic time and random padding ([#18](https://github.com/CargoSense/briefly/pull/18)) @zph
- Add `Briefly.cleanup/0` ([#10](https://github.com/CargoSense/briefly/pull/10)) @gmalkas
- Fix an issue where the sub directory is not created correctly ([#9](https://github.com/CargoSense/briefly/pull/9)) @Schultzer
- Fix error reasons to conform to posix error codes ([#4](https://github.com/CargoSense/briefly/pull/4)) @ngeraedts
- Numerous updates for CI / language changes (h/t @bryanstearns @k-cross @szajbus @devstopfix @sgerrand @mad42 @warmwaffles)

## v0.3.0 (2015-09-06)

Add support for temporary directories

## v0.2.1 (2015-09-03)

Update license

## v0.2.0 (2015-09-03)

Add create options

## v0.1.1 (2015-09-03)

Update docs

## v0.1.0 (2015-09-03)

Initial release
