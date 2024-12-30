defmodule Boneyard.GameServer do
  require Logger
  use GenServer

  alias Boneyard.Game

  def get_game(pid) when is_pid(pid) do
    GenServer.call(pid, :get_game)
  end

  def get_game(game_id) do
    call_by_name(game_id, :get_game)
  end

  def add_player(game_id, name) do
    with {:ok, code, game} <- call_by_name(game_id, {:add_player, name}),
         :ok <- broadcast_player_added!(game_id, game) do
      {:ok, code}
    end
  end

  def update_player_name(game_id, player_index, name) do
    with {:ok, game} <- call_by_name(game_id, {:update_player_name, player_index, name}),
         :ok <- broadcast_game_updated!(game_id, game) do
      {:ok, game}
    end
  end

  def play_tile(game_id, tile_id) do
    with {:ok, tile, game} <- call_by_name(game_id, {:play_tile, tile_id}),
         :ok <- broadcast_game_updated!(game_id, game) do
      {:ok, tile, game}
    end
  end

  def play_tile_on_right_side(game_id, tile_id) do
    with {:ok, tile, game} <- call_by_name(game_id, {:play_tile_on_right_side, tile_id}),
         :ok <- broadcast_game_updated!(game_id, game) do
      {:ok, tile, game}
    end
  end

  def play_tile_on_left_side(game_id, tile_id) do
    with {:ok, tile, game} <- call_by_name(game_id, {:play_tile_on_left_side, tile_id}),
         :ok <- broadcast_game_updated!(game_id, game) do
      {:ok, tile, game}
    end
  end

  def end_game(game_id) do
    call_by_name(game_id, :end_game)
  end

  def pass(game_id) do
    with {:ok, game} <- call_by_name(game_id, :pass),
         :ok <- broadcast_game_updated!(game_id, game) do
      {:ok, game}
    end
  end

  def take_from_boneyard(game_id) do
    with {:ok, tile, game} <- call_by_name(game_id, :take_from_boneyard),
         :ok <- broadcast_game_updated!(game_id, game) do
      {:ok, tile, game}
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

    code =
      Enum.take_random(?A..?Z, 5)
      |> to_string()

    case Game.add_player(state.game, name, code) do
      {:ok, game} ->
        {:reply, {:ok, code, game}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:update_player_name, player_index, name}, _from, state) do
    case Game.update_player_name(state.game, player_index, name) do
      {:ok, game} ->
        {:reply, {:ok, game}, %{state | game: game}}

      {:error, :name_taken} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:play_tile, tile_id}, _from, state) do
    case Game.play_tile(state.game, tile_id) do
      {:ok, tile, game} ->
        {:reply, {:ok, tile, game}, %{state | game: game}}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:play_tile_on_right_side, tile_id}, _from, state) do
    case Game.play_tile_on_right_side(state.game, tile_id) do
      {:ok, tile, game} ->
        {:reply, {:ok, tile, game}, %{state | game: game}}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:play_tile_on_left_side, tile_id}, _from, state) do
    case Game.play_tile_on_left_side(state.game, tile_id) do
      {:ok, tile, game} ->
        {:reply, {:ok, tile, game}, %{state | game: game}}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call(:end_game, _from, state) do
    {:ok, game} = Game.end_game(state.game)
    {:reply, {:ok, game}, %{state | game: game}}
  end

  @impl GenServer
  def handle_call(:take_from_boneyard, _from, state) do
    case Game.take_from_boneyard(state.game) do
      {:ok, tile, game} ->
        {:reply, {:ok, tile, game}, %{state | game: game}}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call(:pass, _from, state) do
    case Game.pass(state.game) do
      {:ok, game} ->
        {:reply, {:ok, game}, %{state | game: game}}

      {:error, _reason} = error ->
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

  defp broadcast_player_added!(game_id, game) do
    broadcast!(to_string(game_id), :player_added, game)
  end

  defp broadcast_game_updated!(game_id, game) do
    broadcast!(to_string(game_id), :game_updated, game)
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Boneyard.GameRegistry, game_id}}
  end
end
