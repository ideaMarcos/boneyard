defmodule BoneyardWeb.GameController do
  use BoneyardWeb, :controller

  alias Boneyard.GameServer

  def join(conn, %{"id" => game_id} = params) do
    name = Map.get(params, "name", "player" <> to_string(Enum.random(1000..9999)))

    case GameServer.add_player(game_id, name) do
      {:ok, code} ->
        conn
        |> put_session(:name, name)
        |> redirect(to: "/game/#{game_id}/#{code}")

      {:error, :too_many_players} ->
        name = Map.get(params, "name", "guest" <> to_string(Enum.random(1000..9999)))

        conn
        |> put_session(:name, name)
        |> redirect(to: "/game/#{game_id}/guest")
    end
  end
end
