# https://hexdocs.pm/phoenix_live_view/welcome.html
defmodule BoneyardWeb.GameLive do
  use Phoenix.LiveView
  alias Boneyard.Cpu
  alias Boneyard.Game

  def render(assigns) do
    ~H"""
    <div>
      <button phx-click="new_game" class="h-10 px-6 font-semibold rounded-md bg-black text-white">
        New game
      </button>
    </div>
    <div :if={!!@game.active_player}>
      <div>
        Current player <%= 1 + @game.active_player %> of <%= @game.num_hands %>
      </div>
      <div>
        <%= for {hand, index} <- Enum.with_index(@game.hands) do %>
          <div class="w-50 bg-white shadow rounded">
            <%= if @game.active_player == index do %>
              ->
            <% else %>
              ....
            <% end %>
            Hand <%= 1 + index %>: <%= print_tiles(hand) %>
          </div>
        <% end %>
      </div>
      <div class="shadow bg-white rounded-lg">
        Playable tiles: <%= playable_tiles(@game) %>
      </div>
    </div>
    <div>
      <button phx-click="play_tile" class="h-10 px-6 font-semibold rounded-md bg-black text-white">
        Play Tile
      </button>
    </div>
    <div class="shadow bg-white rounded-lg">
      Line of play: <%= print_tiles(@game.line_of_play) %>
    </div>
    <div :if={@game.is_round_over}>
      <div>
        Winner is player <%= 1 + @game.winning_player %>
      </div>
      <div>
        Scores <%= inspect(@game.scores) %>
      </div>
    </div>
    """
  end

  defp playable_tiles(%Game{} = game) do
    Game.playable_tiles(game)
    |> Enum.map(fn x -> to_string(x) end)
    |> Enum.join(" , ")
  end

  defp print_tiles(tiles) do
    tiles
    |> Enum.map(fn x -> to_string(x) end)
    |> Enum.join(" , ")
  end

  def mount(_params, _session, socket) do
    # Let's assume a fixed temperature for now
    {:ok, game} = Game.new(4, 7, 6)
    {:ok, assign(socket, :game, game)}
  end

  def handle_event("new_game", _params, socket) do
    game =
      socket.assigns.game

    new_game =
      cond do
        game && game.is_round_over ->
          {:ok, game} = Game.new_round(game)
          game

        game ->
          game

        true ->
          {:ok, game} = Game.new(4, 7, 6)
          game
      end

    {:noreply, update(socket, :game, fn _ -> new_game end)}
  end

  def handle_event("play_tile", _params, socket) do
    Cpu.play_until_round_over(socket.assigns.game)
    |> case do
      # {:ok, _tile, game} ->
      #   {:noreply, update(socket, :game, fn _ -> game end)}

      {:error, :round_over, game} ->
        {:noreply, update(socket, :game, fn _ -> game end)}
    end
  end
end
