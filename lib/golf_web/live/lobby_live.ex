defmodule GolfWeb.LobbyLive do
  use GolfWeb, :live_view
  alias Golf.Games
  alias Golf.Games.Opts

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Lobby</h2>
    <h3>ID: <%= String.upcase(@lobby_id) %></h3>

    <div :if={@lobby}>
      <h4 class="mt-2">Players</h4>
      <p :for={user <- @lobby.users}>
        User(id=<%= user.id %>, name=<%= user.name %>)
      </p>
    </div>

    <form :if={@host?} class="mt-4" phx-submit="start-game">
      <.input name="num-rounds" type="number" min="1" value="1" label="Number of rounds" />
      <.button type="submit">Start Game</.button>
    </form>

    <.button :if={@can_join?} phx-click="join-game">
      Join Game
    </.button>

    <p :if={@lobby && !@host?}>
      Waiting for host to start game...
    </p>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      send(self(), {:load_lobby, id})
    end

    {:ok,
     assign(socket,
       page_title: "Lobby",
       lobby_id: id,
       lobby: nil,
       host?: nil,
       can_join?: nil
     )}
  end

  @impl true
  def handle_info({:load_lobby, id}, %{assigns: %{user: user}} = socket) do
    case Golf.Games.get_lobby(id) do
      nil ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/")
         |> put_flash(:error, "Lobby #{id} not found.")}

      lobby ->
        :ok = Phoenix.PubSub.subscribe(Golf.PubSub, topic(id))

        {:noreply,
         assign(socket,
           lobby: lobby,
           host?: user.id == lobby.host_id,
           can_join?: not Enum.any?(lobby.users, &(&1.id == user.id))
         )}
    end
  end

  @impl true
  def handle_info(
        {:user_joined, lobby, _new_user},
        %{assigns: %{user: user}} = socket
      ) do
    {:noreply,
     assign(socket,
       lobby: lobby,
       can_join?: not Enum.any?(lobby.users, &(&1.id == user.id))
     )}
  end

  @impl true
  def handle_info(:game_created, %{assigns: %{lobby_id: id}} = socket) do
    {:noreply, redirect(socket, to: ~p"/games/#{id}")}
  end

  @impl true
  def handle_event(
        "start-game",
        %{"num-rounds" => num_rounds},
        %{assigns: %{lobby: lobby}} = socket
      ) do
    {num_rounds, _} = Integer.parse(num_rounds)
    opts = %Opts{num_rounds: num_rounds}
    {:ok, game} = Games.create_game(lobby.id, lobby.users, opts)
    :ok = broadcast(lobby.id, :game_created)
    {:noreply, redirect(socket, to: ~p"/games/#{game.id}")}
  end

  @impl true
  def handle_event("join-game", _params, %{assigns: %{lobby: lobby, user: user}} = socket) do
    {:ok, lobby} = Games.add_lobby_user(lobby, user)
    :ok = broadcast(lobby.id, {:user_joined, lobby, user})
    {:noreply, socket}
  end

  defp topic(id), do: "lobby:#{id}"

  defp broadcast(id, msg) do
    Phoenix.PubSub.broadcast(Golf.PubSub, topic(id), msg)
  end
end
