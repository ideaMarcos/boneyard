# Boneyard

[![License](https://img.shields.io/github/license/ideaMarcos/boneyard.svg)](https://github.com/ideaMarcos/boneyard/blob/main/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/ideaMarcos/boneyard.svg)](https://github.com/ideaMarcos/boneyard/commits/main)


To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

```
iex(1)> alias Boneyard.Game
iex(2)> {:ok, game} = Game.new(4, 7, 6)
iex(3)> Game.playable_tiles(game)
iex(4)> {:ok, game} = Game.play_random_tile(game)

```

## Random

- `mix phx.new boneyard --no-ecto --no-mailer`
