defmodule BoneyardWeb.HomeLive do
  use BoneyardWeb, :live_view

  alias Boneyard.Game
  alias Boneyard.GameSupervisor
  alias Boneyard.Schema.GameOptions

  def mount(_params, _session, socket) do
    changeset = GameOptions.new() |> GameOptions.changeset(%{"player_name" => ""})
    {:ok, assign(socket, form: to_form(changeset))}
  end

  def handle_event("create_game", params, socket) do
    GameOptions.new()
    |> GameOptions.changeset(params)
    |> GameOptions.apply_update_action()
    |> case do
      {:ok, game_options} ->
        game_id = Game.new_game_id()
        GameSupervisor.start_game(game_id)

        {:noreply,
         socket
         |> redirect(to: "/game/join/#{game_id}?name=#{game_options.player_name}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
