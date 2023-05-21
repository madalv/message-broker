FROM elixir:latest

WORKDIR /app

COPY . .

RUN mix local.hex --force

RUN mix deps.get 

CMD mix run /app/lib/script.exs