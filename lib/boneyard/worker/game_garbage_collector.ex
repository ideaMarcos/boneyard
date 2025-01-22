defmodule Boneyard.Workers.GameGarbageCollector do
  use Oban.Worker
  require Logger
  alias Boneyard.GameServer
  alias Boneyard.GameSupervisor

  @impl Oban.Worker
  def perform(%Oban.Job{args: _args}) do
    Logger.info("Garbage collecting games")

    GameSupervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} ->
      {:ok, game} = GameServer.get_game(pid)

      if game.game_over? do
        Logger.info("Stopping game #{game.id}")
        GameSupervisor.stop_game(game.id)
      end
    end)

    :ok
  end
end
