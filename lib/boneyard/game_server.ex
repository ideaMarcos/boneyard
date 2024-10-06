defmodule Boneyard.GameServer do
  require Logger
  use GenServer

  alias Boneyard.Game

  def get_game(game_id) do
    call_by_name(game_id, :get_game)
  end

  def add_player(game_id, name) do
    with {:ok, code, players} <- call_by_name(game_id, {:add_player, name}),
         :ok <- broadcast_players_updated!(game_id, players) do
      {:ok, code}
    end
  end

  def start_link(game_id) do
    GenServer.start(__MODULE__, game_id, name: via_tuple(game_id))
  end

  def game_pid(game_id) do
    game_id
    |> via_tuple()
    |> GenServer.whereis()
  end

  @impl GenServer
  def init(game_id) do
    Logger.info("Creating game server for #{game_id})")
    {:ok, game} = Game.new(game_id)
    {:ok, %{game: game}}
  end

  @impl GenServer
  def handle_call(:get_game, _from, state) do
    {:reply, {:ok, state.game}, state}
  end

  @impl GenServer
  def handle_call({:add_player, name}, _from, state) do
    name = name |> String.trim() |> String.downcase()
    code = Enum.take_random(?A..?Z, 5)

    case Game.add_player(state.game, name, code) |> IO.inspect() do
      {:ok, game} ->
        {:reply, {:ok, code, game.player_names}, %{state | game: game}}

      {:error, :name_taken} = error ->
        {:reply, error, state}
    end
  end

  @spec broadcast!(String.t(), atom(), map()) :: :ok
  def broadcast!(game_id, event, payload \\ %{}) do
    Phoenix.PubSub.broadcast!(Boneyard.PubSub, game_id, %{event: event, payload: payload})
  end

  defp call_by_name(game_id, command) do
    case game_pid(game_id) do
      game_pid when is_pid(game_pid) ->
        GenServer.call(game_pid, command)

      nil ->
        {:error, :game_not_found}
    end
  end

  # defp cast_by_name(game_id, command) do
  #   case game_pid(game_id) do
  #     game_pid when is_pid(game_pid) ->
  #       GenServer.cast(game_pid, command)

  #     nil ->
  #       {:error, :game_not_found}
  #   end
  # end

  defp broadcast_players_updated!(game_id, players) do
    broadcast!(to_string(game_id), :players_updated, players)
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Boneyard.GameRegistry, game_id}}
  end
end
