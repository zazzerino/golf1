defmodule GolfWeb.LobbyLive do
  use GolfWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Lobby</h2>
    <h3>ID: <%= String.upcase(@lobby_id) %></h3>

    <h4 class="mt-2">Users</h4>
    <div :for={user <- @users}>
      <p>User(id=<%= user.id %>, name=<%= user.name %>)</p>
    </div>

    <form :if={@host?} class="mt-4" phx-submit="create-game">
      <.input name="num-rounds" type="number" min="1" value="1" label="Number of rounds" />
      <.button type="submit">Start Game</.button>
    </form>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, %{assigns: %{user: user}} = socket) do
    if connected?(socket) do
      send(self(), {:load_lobby, id})
    end

    {:ok,
     assign(socket, page_title: "Lobby", lobby_id: id, users: [user], lobby: nil, host?: nil)}
  end

  @impl true
  def handle_info({:load_lobby, id}, %{assigns: %{user: user}} = socket) do
    with lobby when is_struct(lobby) <- Golf.Games.get_lobby(id),
         users when is_list(users) <- Golf.Users.get_users(lobby.user_ids),
         host? <- user.id == lobby.host_id,
         :ok <- Phoenix.PubSub.subscribe(Golf.PubSub, "lobby:#{id}") do
      {:noreply, assign(socket, lobby: lobby, users: users, host?: host?)}
    else
      _ ->
        {:noreply, socket |> redirect(to: ~p"/") |> put_flash(:error, "Lobby #{id} not found.")}
    end
  end

  @impl true
  def handle_event(
        "create-game",
        %{"num-rounds" => num_rounds},
        %{assigns: %{lobby_id: id, users: users}} = socket
      ) do
    {num_rounds, _} = Integer.parse(num_rounds)
    opts = %Golf.Games.Opts{num_rounds: num_rounds}
    {:ok, game} = Golf.Games.create_game(id, users, opts)
    {:noreply, redirect(socket, to: ~p"/games/#{game.id}")}
  end

  @impl true
  def handle_event("player-join", _params, socket) do
    {:noreply, socket}
  end
end
