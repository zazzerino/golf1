defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view
  alias Golf.Games
  alias Golf.Games.Event

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Game</h2>
    <h3><%= String.upcase(@game_id) %></h3>

    <div id="game-canvas" phx-hook="GameCanvas" phx-update="ignore"></div>

    <.button :if={@can_start?} class="mt-2" phx-click="start-round">
      Start Round
    </.button>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      send(self(), {:load_game, id})
    end

    {:ok,
     assign(socket,
       page_title: "Game",
       game_id: id,
       game: nil,
       player: nil,
       host?: nil,
       can_start?: nil
     )}
  end

  @impl true
  def handle_info({:load_game, id}, %{assigns: %{user: user}} = socket) do
    case Games.fetch_game(id) do
      {:ok, game} ->
        host? = user.id == game.host_id
        can_start? = host? && !Games.current_round(game)
        :ok = Phoenix.PubSub.subscribe(Golf.PubSub, "game:#{id}")

        {:noreply,
         socket
         |> assign(game: game, host?: host?, can_start?: can_start?)
         |> push_event("game-loaded", %{"game" => Games.Data.from(game, user.id)})}

      _ ->
        {:noreply, socket |> redirect(to: ~p"/") |> put_flash(:error, "Game #{id} not found.")}
    end
  end

  @impl true
  def handle_info({:round_started, game}, %{assigns: %{user: user}} = socket) do
    {:noreply,
     socket
     |> assign(game: game, can_start?: false)
     |> push_event("round-started", %{"game" => Games.Data.from(game, user.id)})}
  end

  @impl true
  def handle_info({:game_event, game, event}, %{assigns: %{user: user}} = socket) do
    {:noreply,
     socket
     |> assign(game: game)
     |> push_event("game-event", %{"game" => Games.Data.from(game, user.id), "event" => event})}
  end

  @impl true
  def handle_event("start-round", _params, %{assigns: %{game: game}} = socket) do
    {:ok, game} = Games.start_round(game)
    :ok = broadcast(game.id, {:round_started, game})
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "hand-click",
        %{"playerId" => player_id, "handIndex" => hand_index},
        %{assigns: %{game: game}} = socket
      ) do
    handle_game_event(game, "hand", player_id, hand_index)
    {:noreply, socket}
  end

  @impl true
  def handle_event("deck-click", %{"playerId" => player_id}, %{assigns: %{game: game}} = socket) do
    handle_game_event(game, "deck", player_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("table-click", %{"playerId" => player_id}, %{assigns: %{game: game}} = socket) do
    handle_game_event(game, "table", player_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("held-click", %{"playerId" => player_id}, %{assigns: %{game: game}} = socket) do
    handle_game_event(game, "held", player_id)
    {:noreply, socket}
  end

  defp handle_game_event(game, place, player_id, hand_index \\ nil) do
    player = Enum.find(game.players, &(&1.id == player_id))
    action = current_action(Games.state(game), place)
    event = Event.new(game, player, action, hand_index)

    {:ok, game} = Games.handle_event(game, event)
    :ok = broadcast(game.id, {:game_event, game, event})
  end

  defp current_action(state, place) do
    case {state, place} do
      {:flip_2, "hand"} ->
        :flip

      {:flip, "hand"} ->
        :flip

      {:take, "deck"} ->
        :take_from_deck

      {:take, "table"} ->
        :take_from_table

      {:hold, "held"} ->
        :discard
    end
  end

  defp broadcast(game_id, msg) do
    Phoenix.PubSub.broadcast(Golf.PubSub, "game:#{game_id}", msg)
  end
end
