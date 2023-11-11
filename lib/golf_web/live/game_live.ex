defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view
  alias Golf.Games

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Game <%= @game_id %></h2>
    <div>
      <div id="game-canvas" phx-hook="GameCanvas" phx-update="ignore"></div>
    </div>
    <div>
      <.button :if={@can_start_round?} phx-click="start_round">
        Start Round
      </.button>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    with {id, _} <- Integer.parse(id) do
      if connected?(socket) do
        send(self(), {:load_game, id})
      end

      {:ok, assign(socket, page_title: "Game #{id}", game_id: id, can_start_round?: false)}
    else
      _ ->
        {:ok,
         socket
         |> redirect(to: ~p"/")
         |> put_flash(:error, "#{id} is not a valid game id.")}
    end
  end

  @impl true
  def handle_info({:load_game, id}, %{assigns: %{user: user}} = socket) do
    case Games.Db.get_game(id) do
      nil ->
        {:noreply, socket |> redirect(to: ~p"/") |> put_flash(:error, "Game #{id} not found.")}

      game ->
        user_is_host? = user.id == game.host_id
        round = List.first(game.rounds)
        can_start_round? = user_is_host? && !round
        :ok = Phoenix.PubSub.subscribe(Golf.PubSub, "game:#{id}")

        {:noreply,
         socket
         |> assign(game: game, can_start_round?: can_start_round?)
         |> push_event("game-loaded", %{"game" => Games.Data.from(game, user.id)})}
    end
  end

  @impl true
  def handle_info({:round_started, game}, %{assigns: %{user: user}} = socket) do
    {:noreply,
     socket
     |> assign(game: game, can_start_round?: false)
     |> push_event("round-started", %{"game" => Games.Data.from(game, user.id)})}
  end

  @impl true
  def handle_event("start_round", _params, %{assigns: %{game: game}} = socket) do
    {:ok, game} =
      game
      |> Games.start_next_round()
      |> Games.Db.upsert_game()

    :ok = broadcast(game.id, {:round_started, game})
    {:noreply, socket}
  end

  defp broadcast(game_id, msg) do
    Phoenix.PubSub.broadcast(Golf.PubSub, "game:#{game_id}", msg)
  end
end
