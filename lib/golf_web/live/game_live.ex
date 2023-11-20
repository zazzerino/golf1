defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view

  alias Golf.Games
  alias Golf.Games.{Event, Player}

  defp topic(id), do: "game:#{id}"

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Game <%= @link_id %></h2>

    <div id="game-wrapper">
      <div id="game-canvas" phx-hook="GameCanvas" phx-update="ignore"></div>
      <div>
        <.player_score :for={p <- @players} player={p} />
      </div>
    </div>

    <.button :if={@can_start?} class="mt-2" phx-click="start-round">
      Start Round
    </.button>
    """
  end

  defp player_score(assigns) do
    ~H"""
    <div class={"player-score #{@player.position}"}>
      <%= @player.username %>(score=<%= @player.score %>)
    </div>
    """
  end

  @impl true
  def mount(%{"id" => link_id}, _session, socket) do
    if connected?(socket) do
      send(self(), {:load_game, link_id})
    end

    {:ok,
     assign(socket,
       page_title: "Game",
       link_id: link_id,
       game: nil,
       players: [],
       player: nil,
       can_start?: nil
     )}
  end

  @impl true
  def handle_info({:load_game, link_id}, %{assigns: %{user: user}} = socket) do
    if game = Golf.Links.get_game(link_id) do
      can_start? = user.id == game.host_id && !Games.current_round(game)
      data = Games.Data.from(game, user.id)
      :ok = Golf.subscribe(topic(game.id))

      {:noreply,
       socket
       |> assign(game: game, players: data.players, can_start?: can_start?)
       |> push_event("game-loaded", %{"game" => data})}
    else
      {:noreply,
       socket
       |> push_navigate(to: ~p"/")
       |> put_flash(:error, "Game #{link_id} not found.")}
    end
  end

  @impl true
  def handle_info({:round_started, game}, socket) do
    {:noreply,
     socket
     |> assign(game: game, can_start?: false)
     |> push_event("round-started", %{"game" => Games.Data.from(game, socket.assigns.user.id)})}
  end

  @impl true
  def handle_info({:game_event, game, event}, socket) do
    data = Games.Data.from(game, socket.assigns.user.id)

    {:noreply,
     socket
     |> assign(game: game)
     |> assign(players: data.players)
     |> push_event("game-event", %{"game" => data, "event" => event})}
  end

  @impl true
  def handle_event("start-round", _params, socket) do
    {:ok, game} = Games.start_round(socket.assigns.game)
    :ok = Golf.broadcast(topic(game.id), {:round_started, game})
    {:noreply, socket}
  end

  @impl true
  def handle_event("hand-click", %{"playerId" => player_id, "handIndex" => hand_index}, socket) do
    handle_game_event(socket.assigns.game, "hand", player_id, hand_index)
    {:noreply, socket}
  end

  @impl true
  def handle_event("deck-click", %{"playerId" => player_id}, socket) do
    handle_game_event(socket.assigns.game, "deck", player_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("table-click", %{"playerId" => player_id}, socket) do
    handle_game_event(socket.assigns.game, "table", player_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("held-click", %{"playerId" => player_id}, socket) do
    handle_game_event(socket.assigns.game, "held", player_id)
    {:noreply, socket}
  end

  defp handle_game_event(game, place, player_id, hand_index \\ nil) do
    %Player{} = player = Enum.find(game.players, &(&1.id == player_id))

    action =
      Games.current_state(game)
      |> action_at(place)

    event = Event.new(game, player, action, hand_index)
    {:ok, game} = Games.handle_event(game, event)
    :ok = Golf.broadcast(topic(game.id), {:game_event, game, event})
  end

  defp action_at(state, "hand") when state in [:flip_2, :flip], do: :flip
  defp action_at(:take, "table"), do: :take_from_table
  defp action_at(:take, "deck"), do: :take_from_deck
  defp action_at(:hold, "held"), do: :discard
  defp action_at(:hold, "hand"), do: :swap
end
