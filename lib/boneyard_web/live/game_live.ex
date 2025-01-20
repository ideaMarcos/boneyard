# https://hexdocs.pm/phoenix_live_view/welcome.html
defmodule BoneyardWeb.GameLive do
  use BoneyardWeb, :live_view

  require Logger
  alias Boneyard.Game
  alias Boneyard.GameServer
  alias Boneyard.Presence
  alias Boneyard.Schema.GameOptions
  alias Boneyard.Tile
  alias Phoenix.LiveView.JS

  defp can_take_from_boneyard?(%Game{} = game) do
    case Game.take_from_boneyard(game) do
      {:ok, _, _} -> true
      _ -> false
    end
  end

  defp is_playable_tile?(%Game{} = game, %Tile{} = tile) do
    tile in Game.playable_tiles(game)
  end

  defp has_playable_tiles?(%Game{} = game) do
    Game.playable_tiles(game) != []
  end

  defp hand_class(%Game{} = game, hand_index) do
    if game.active_player == hand_index do
      "player-hand active"
    else
      "player-hand"
    end
  end

  def mount(params, session, socket) do
    game_id = Map.get(params, "id")
    player_code = Map.get(params, "player_code")
    {:ok, game} = GameServer.get_game(game_id)

    player_index =
      Enum.find_index(game.player_codes, fn x -> x == player_code end) || -1

    with %{"name" => name} <- session do
      if String.starts_with?(name, "guest") do
        Presence.track(self(), game_id, name, %{emoji: random_emoji()})
      end
    end

    Presence.subscribe(game_id)

    presences =
      Presence.list(game_id)
      |> Presence.simple_presence_map()

    changeset = GameOptions.new() |> GameOptions.changeset(%{})

    {:ok,
     socket
     |> assign(:game, game)
     |> assign(:audience_changed, false)
     |> assign(:presences, presences)
     |> assign_new(:my_player_index, fn -> player_index end)
     |> assign(:my_player_code, player_code)
     |> assign(:show_edit_name_modal, false)
     |> assign(:form, to_form(changeset))}
  end

  defp random_emoji() do
    [128_640..128_676, 128_000..128_063, 129_408..129_455] |> Enum.random() |> Enum.random()
  end

  defp audience_emoji(audience_changed, audience_size) do
    cond do
      audience_changed -> "🫥"
      audience_size > 2 -> "😁"
      true -> "🙂"
    end
  end

  def handle_event("finish_round", _params, socket) do
    {:ok, _} = GameServer.play_until_round_over(socket.assigns.game.id)
    {:noreply, socket}
  end

  def handle_event("new_round", _params, socket) do
    {:ok, _} = GameServer.new_round(socket.assigns.game.id)
    {:noreply, socket}
  end

  def handle_event("play_tile", %{"id" => tile_id, "side" => side}, socket) do
    result =
      case side do
        "left" -> GameServer.play_tile_on_left_side(socket.assigns.game.id, tile_id)
        "right" -> GameServer.play_tile_on_right_side(socket.assigns.game.id, tile_id)
        _ -> GameServer.play_tile(socket.assigns.game.id, tile_id)
      end

    case result do
      {:ok, _tile, game} -> {:noreply, update(socket, :game, fn _ -> game end)}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("take_from_boneyard", _params, socket) do
    {:ok, _tile, _game} = GameServer.take_from_boneyard(socket.assigns.game.id)
    {:noreply, socket}
  end

  def handle_event("pass", _params, socket) do
    {:ok, _game} = GameServer.pass(socket.assigns.game.id)
    {:noreply, socket}
  end

  def handle_event("edit_name", _params, socket) do
    name = Enum.at(socket.assigns.game.player_names, socket.assigns.my_player_index)
    changeset = GameOptions.new() |> GameOptions.changeset(%{"player_name" => name})

    {:noreply,
     socket
     |> assign(:show_edit_name_modal, true)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("save_name", %{"game_options" => %{"player_name" => name}}, socket) do
    game = socket.assigns.game
    my_player_index = socket.assigns.my_player_index

    with changeset <-
           GameOptions.new()
           |> GameOptions.changeset(%{"player_name" => name}),
         {:ok, game_options} <- GameOptions.apply_update_action(changeset),
         {:ok, game} <-
           update_player_name(game.id, my_player_index, game_options.player_name, changeset) do
      {:noreply,
       socket
       |> assign(:game, game)
       |> assign(:show_edit_name_modal, false)
       |> put_temporary_flash(:info, "Name updated successfully")}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset))}

      {:error, :name_taken, changeset} ->
        form =
          to_form(changeset)
          |> Map.update!(:errors, fn x ->
            Keyword.put(x, :player_name, {"Name already taken", []})
          end)

        {:noreply, assign(socket, :form, form)}
    end
  end

  def update_player_name(game_id, my_player_index, player_name, changeset) do
    with {:ok, game} <- GameServer.update_player_name(game_id, my_player_index, player_name) do
      {:ok, game}
    else
      {:error, reason} -> {:error, reason, changeset}
    end
  end

  def handle_info(%{event: :player_added, payload: game}, socket) do
    player_index =
      Enum.find_index(game.player_codes, fn x -> x == socket.assigns.my_player_code end)

    {:noreply,
     socket
     |> update(:my_player_index, fn _ -> player_index end)
     |> update(:game, fn _ -> game end)}
  end

  def handle_info(%{event: :game_updated, payload: game}, socket) do
    {:noreply, update(socket, :game, fn _ -> game end)}
  end

  def handle_info({:clear_flash, level}, socket) do
    {:noreply, clear_flash(socket, Atom.to_string(level))}
  end

  def handle_info(:clear_audience_changed, socket) do
    {:noreply, assign(socket, :audience_changed, false)}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    # Presence.list(socket.assigns.game.id)
    # |> IO.inspect(label: "EVENT presence_diff")

    {:noreply,
     socket
     |> put_audience_changed()
     |> Presence.handle_diff(diff)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  attr :tile, Tile

  def player_tile(assigns) do
    ~H"""
    <div class="domino" aria-label="Domino {@tile.left_val}/{@tile.right_val}">
      <div class="domino-half">{@tile.right_val}</div>
      <div class="domino-divider"></div>
      <div class="domino-half">{@tile.left_val}</div>
    </div>
    """
  end

  attr :tile, Tile

  def line_of_play_tile(assigns) do
    ~H"""
    <div
      class={if Tile.is_double(@tile), do: "domino", else: "domino horizontal"}
      role="listitem"
      aria-label="Domino {@tile.left_val}/{@tile.right_val}"
    >
      <div class="domino-half">{@tile.left_val}</div>
      <div class="domino-divider"></div>
      <div class="domino-half">{@tile.right_val}</div>
    </div>
    """
  end

  attr :val, :integer, default: 0

  def small_tile(assigns) do
    ~H"""
    <div class="domino-small">
      <div class="domino-half">{if @val != 0, do: @val, else: ""}</div>
    </div>
    """
  end

  defp put_audience_changed(socket) do
    Process.send_after(self(), :clear_audience_changed, 1000)
    assign(socket, :audience_changed, true)
  end

  defp put_temporary_flash(socket, level, message) do
    Process.send_after(self(), {:clear_flash, level}, 3000)
    put_flash(socket, level, message)
  end
end
