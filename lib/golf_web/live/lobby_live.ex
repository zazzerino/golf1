defmodule GolfWeb.LobbyLive do
  use GolfWeb, :live_view

  alias Golf.Lobbies
  alias Golf.Games.Opts

  def topic(id), do: "lobby:#{id}"

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Lobby <%= @link_id %></h2>

    <div :if={@lobby}>
      <h4 class="mt-2">Players</h4>
      <p :for={user <- @lobby.users}>
        User(id=<%= user.id %>, name=<%= user.name %>)
      </p>
    </div>

    <.opts_form :if={@host?} />

    <.button :if={@can_join?} phx-click="join-lobby" class="my-2">
      Join
    </.button>

    <p :if={@lobby && !@host?} class="mt-4">
      Waiting for host to start game...
    </p>
    """
  end

  def opts_form(assigns) do
    ~H"""
    <.simple_form for={%{}} phx-submit="start-game">
      <.input name="num-rounds" type="number" min="1" value="1" label="Number of rounds" />
      <:actions>
        <.button>Start Game</.button>
      </:actions>
    </.simple_form>
    """
  end

  @impl true
  def mount(%{"id" => link_id}, _session, socket) do
    if connected?(socket) do
      send(self(), {:load_lobby, link_id})
    end

    {:ok,
     assign(socket,
       page_title: "Lobby",
       link_id: link_id,
       lobby: nil,
       host?: nil,
       can_join?: nil
     )}
  end

  @impl true
  def handle_info({:load_lobby, link_id}, %{assigns: %{user: user}} = socket) do
    case Golf.Links.get_lobby(link_id) do
      nil ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/")
         |> put_flash(:error, "Lobby #{link_id} not found.")}

      lobby ->
        :ok = Golf.subscribe(topic(lobby.id))

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
        {:user_joined, new_user},
        %{assigns: %{user: user, lobby: lobby}} = socket
      ) do
    lobby = %{lobby | users: lobby.users ++ [new_user]}

    {:noreply,
     assign(socket,
       lobby: lobby,
       can_join?: not Enum.any?(lobby.users, &(&1.id == user.id))
     )
     |> put_flash(:info, "User joined: #{new_user.name}(id=#{new_user.id})")}
  end

  @impl true
  def handle_info(:game_created, socket) do
    {:noreply, push_navigate(socket, to: ~p"/game/#{socket.assigns.link_id}")}
  end

  @impl true
  def handle_event("join-lobby", _params, %{assigns: %{lobby: lobby, user: user}} = socket) do
    {:ok, lobby} = Lobbies.add_lobby_user(lobby, user)
    :ok = Golf.broadcast(topic(lobby.id), {:user_joined, user})
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "start-game",
        %{"num-rounds" => num_rounds},
        %{assigns: %{lobby: lobby, link_id: link_id}} = socket
      ) do
    {num_rounds, _} = Integer.parse(num_rounds)
    opts = %Opts{num_rounds: num_rounds}
    {:ok, _} = Golf.Links.create_link_game(link_id, lobby.users, opts)
    :ok = Golf.broadcast_from(topic(lobby.id), :game_created)
    {:noreply, push_navigate(socket, to: ~p"/game/#{link_id}")}
  end
end
