# https://hexdocs.pm/phoenix_live_view/welcome.html
defmodule BoneyardWeb.HomeLive do
  use Phoenix.LiveView

  alias Boneyard.Game
  alias Boneyard.GameServer
  alias Boneyard.GameSupervisor

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("new_game", _params, socket) do
    game_id = Game.new_game_id()
    GameSupervisor.start_game(game_id)
    name = "player" <> to_string(Enum.random(1000..9999))

    socket =
      case GameServer.add_player(game_id, name) do
        {:ok, code} ->
          socket
          |> put_flash(:info, "Joined successfully")
          |> push_navigate(to: "/game/#{game_id}/#{code}")

        {:error, :name_taken} ->
          socket
          |> put_temporary_flash(:error, "Name already taken, please choose a different name")

        {:error, :too_many_players} ->
          socket
          |> put_temporary_flash(:error, "Too many players")
      end

    {:noreply, socket}
  end

  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
