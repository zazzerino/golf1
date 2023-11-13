defmodule GolfWeb.NewGameLive do
  use GolfWeb, :live_view
  alias Golf.Games

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Game Options</h2>
    <h3>Game ID: <%= String.upcase(@id) %></h3>
    <h4 class="mt-2">Players</h4>
    <div :for={user <- @users}>
      <p>User(id=<%= user.id %>, name=<%= user.name %>)</p>
    </div>
    <form class="mt-4" phx-submit="create-game">
      <.input name="num-rounds" type="number" min="1" value="1" label="Number of rounds" />
      <.button type="submit">Start Game</.button>
    </form>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, %{assigns: %{user: user}} = socket) do
    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Golf.PubSub, "opts:#{id}")
    end

    {:ok, assign(socket, page_title: "Game Opts", id: id, users: [user])}
  end

  @impl true
  def handle_event(
        "create-game",
        %{"num-rounds" => num_rounds},
        %{assigns: %{id: id, user: user}} = socket
      ) do
    {num_rounds, _} = Integer.parse(num_rounds)
    opts = %Games.Opts{num_rounds: num_rounds}
    {:ok, game} = Games.create_game(id, user, opts)
    {:noreply, redirect(socket, to: ~p"/games/#{game.id}")}
  end

  @impl true
  def handle_event("player-join", _params, socket) do
    {:noreply, socket}
  end
end
