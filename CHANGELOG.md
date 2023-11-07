## v0.5.0

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

### Exceptions

The following exceptions may now be returned from `Briefly.create/1`:

- `%Briefly.NoRootDirectoryError{}` - returned when a root temporary directory could not be accessed.

- `%Briefly.WriteError{}` - returned when an entry cannot be created.

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
