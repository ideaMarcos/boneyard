defmodule BoneyardWeb.HomeLive do
  use BoneyardWeb, :live_view

  alias Boneyard.Game
  alias Boneyard.GameSupervisor
  alias BoneyardWeb.Changeset.NewGame

  def mount(_params, _session, socket) do
    changeset = NewGame.new() |> NewGame.changeset(%{})
    {:ok, assign(socket, changeset: changeset)}
  end

  def handle_event("new_game", params, socket) do
    changeset = NewGame.new() |> NewGame.changeset(params)

    if changeset.valid? do
      new_game = NewGame.apply(changeset)

      game_id = Game.new_game_id()
      GameSupervisor.start_game(game_id)

      socket =
        socket
        |> put_flash(:info, "Joined successfully")
        |> assign(:player_name, new_game.player_name)
        |> push_navigate(to: "/game/join/#{game_id}?name=#{new_game.player_name}")

      {:noreply, socket}
    else
      {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # defp put_temporary_flash(socket, level, message) do
  #   :timer.send_after(:timer.seconds(3), {:clear_flash, level})

  #   put_flash(socket, level, message)
  # end
end
