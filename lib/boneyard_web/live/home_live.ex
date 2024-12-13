# https://hexdocs.pm/phoenix_live_view/welcome.html
defmodule BoneyardWeb.HomeLive do
  use Phoenix.LiveView

  alias Boneyard.Game
  alias Boneyard.GameSupervisor

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("new_game", _params, socket) do
    game_id = Game.new_game_id()
    GameSupervisor.start_game(game_id)

    socket =
      socket
      |> put_flash(:info, "Joined successfully")
      |> push_navigate(to: "/game/join/#{game_id}")

    {:noreply, socket}
  end

  # defp put_temporary_flash(socket, level, message) do
  #   :timer.send_after(:timer.seconds(3), {:clear_flash, level})

  #   put_flash(socket, level, message)
  # end
end
