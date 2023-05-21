# Lab 3 PTR (Message Broker)

An implementation of a Message Broker in Elixir. Find out way more in `/report/report.md`.

## Starting the Project

To run locally:

```bash
mix run lib/script.exs
```

To run the Docker container:

```bash
docker compose up --build
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `messagebroker` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:messagebroker, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/messagebroker](https://hexdocs.pm/messagebroker).

