defmodule GolfWeb.GameOptsLive do
  use GolfWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Game Options</h2>
    <h4 class="mt-2">Players</h4>
    <div :for={user <- @users}>
      <p>User(id=<%= user.id %>, name=<%= user.name %>)</p>
    </div>
    <form class="mt-4" phx-submit="create-game">
      <.input name="num_rounds" type="number" min="1" value="1" label="Number of rounds" />
      <.button type="submit">Start Game</.button>
    </form>
    """
  end

  @impl true
  def mount(%{"id" => room_id}, _session, %{assigns: %{user: user}} = socket) do
    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Golf.PubSub, "opts:#{room_id}")
    end

    {:ok, assign(socket, page_title: "Game Opts", users: [user])}
  end

  @impl true
  def handle_event(
        "create-game",
        %{"num_rounds" => num_rounds},
        %{assigns: %{user: user}} = socket
      ) do
    {num_rounds, _} = Integer.parse(num_rounds)
    {:ok, game} = Golf.Games.create_game(user, num_rounds: num_rounds)
    {:noreply, redirect(socket, to: ~p"/games/#{game.id}")}
  end
end
