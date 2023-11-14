defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view
  alias Golf.Games
  alias Golf.Games.{Game, Round}

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Game</h2>
    <h3><%= String.upcase(@game_id) %></h3>
    <div id="game-canvas" phx-hook="GameCanvas" phx-update="ignore"></div>

    <div>
      <.button :if={@can_start?} phx-click="start-round">
        Start Round
      </.button>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      send(self(), {:load_game, id})
    end

    {:ok, assign(socket, page_title: "Game", game_id: id, can_start?: nil)}
  end

  @impl true
  def handle_info({:load_game, id}, %{assigns: %{user: user}} = socket) do
    case Games.get_game(id) do
      nil ->
        {:noreply, socket |> redirect(to: ~p"/") |> put_flash(:error, "Game #{id} not found.")}

      game ->
        user_is_host? = user.id == game.host_id
        round = Games.current_round(game)
        # TODO
        can_start? = user_is_host? && !round
        :ok = Phoenix.PubSub.subscribe(Golf.PubSub, "game:#{id}")

        {:noreply,
         socket
         |> assign(game: game, can_start?: can_start?)
         |> push_event("game-loaded", %{"game" => Games.Data.from(game, user.id)})}
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
    {:ok, game} = Games.start_next_round(game)
    :ok = broadcast(game.id, {:round_started, game})
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "hand-click",
        %{"playerId" => player_id, "handIndex" => hand_index},
        %{assigns: %{game: %Game{rounds: [round | _]} = game}} = socket
      )
      when round.state in [:flip_2, :flip] do
    event = Games.Event.new(round.id, player_id, :flip, hand_index)
    {:ok, game} = Games.handle_event(game, event)
    :ok = broadcast(game.id, {:game_event, game, event})
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "deck-click",
        %{"playerId" => player_id},
        %{assigns: %{game: %Game{rounds: [%Round{id: round_id, state: :take} | _]} = game}} =
          socket
      ) do
    event = Games.Event.new(round_id, player_id, :take_from_deck)
    {:ok, game} = Games.handle_event(game, event)
    :ok = broadcast(game.id, {:game_event, game, event})
    {:noreply, socket}
  end

  defp broadcast(game_id, msg) do
    Phoenix.PubSub.broadcast(Golf.PubSub, "game:#{game_id}", msg)
  end
end
