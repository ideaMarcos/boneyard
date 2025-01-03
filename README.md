# Boneyard - WIP Domino game using Liveview for 2-4 players


[![License](https://img.shields.io/github/license/ideaMarcos/boneyard.svg)](https://github.com/ideaMarcos/boneyard/blob/main/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/ideaMarcos/boneyard.svg)](https://github.com/ideaMarcos/boneyard/commits/main)


To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).




https://github.com/user-attachments/assets/2d5d58f2-2657-4b70-a463-fa30af41ab92



```
iex> alias Boneyard.{Cpu, Game}
iex> {:ok, game} = Game.new(4, 7, 6)
iex> Game.playable_tiles(game)
iex> {:ok, tile, game} = Cpu.play_random_tile(game)
iex> {:error, reason, game} = Cpu.play_until_round_over(game)

```

## Random

- `mix phx.new boneyard --no-ecto --no-mailer`
