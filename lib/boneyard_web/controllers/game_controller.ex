defmodule BoneyardWeb.GameController do
  use BoneyardWeb, :controller

  alias Boneyard.GameServer

  def join(conn, %{"id" => game_id} = params) do
    player_name = Map.get(params, "name", "player" <> to_string(Enum.random(1000..9999)))

    case GameServer.add_player(game_id, player_name) do
      {:ok, code} ->
        # {:error, :name_taken} ->
        #   socket
        #   |> put_temporary_flash(:error, "Name already taken, please choose a different name")

        # {:error, :too_many_players} ->
        #   socket
        #   |> put_temporary_flash(:error, "Too many players")

        conn
        |> put_session(:game_id, game_id)
        |> redirect(to: "/game/#{game_id}/#{code}")
    end
  end
end
