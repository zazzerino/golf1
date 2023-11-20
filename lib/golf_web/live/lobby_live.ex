defmodule GolfWeb.LobbyLive do
  use GolfWeb, :live_view
  import GolfWeb.Components, only: [opts_form: 1, chat: 1]
  alias Golf.Lobbies
  alias Golf.Games.Opts

  def topic(id), do: "lobby:#{id}"

  @impl true
  def render(assigns) do
    ~H"""
    <h2 class="text-2xl mb-2">
      <span class="font-bold">Lobby</span> <%= @link_id %>
    </h2>

    <.opts_form :if={@host?} />

    <div :if={@lobby}>
      <h4 class="mt-4 font-bold">Players</h4>
      <p :for={user <- @lobby.users}>
        User(id=<%= user.id %>, name=<%= user.name %>)
      </p>
    </div>

    <.button :if={@can_join?} phx-click="join-lobby" class="my-2">
      Join
    </.button>

    <.chat messages={@streams.messages} submit="submit-chat" />

    <p :if={@lobby && !@host?} class="mt-4">
      Waiting for host to start game...
    </p>
    """
  end

  @impl true
  def mount(%{"link_id" => link_id}, _session, socket) do
    if connected?(socket) do
      send(self(), {:load_lobby, link_id})
      send(self(), {:load_messages, link_id})
    end

    {:ok,
     assign(socket,
       page_title: "Lobby",
       link_id: link_id,
       lobby: nil,
       host?: nil,
       can_join?: nil
     )
     |> stream(:messages, [])}
  end

  @impl true
  def handle_info({:load_lobby, link_id}, socket) do
    case Golf.Links.get_lobby(link_id) do
      nil ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/")
         |> put_flash(:error, "Lobby #{link_id} not found.")}

      lobby ->
        :ok = Golf.subscribe(topic(lobby.id))
        host? = lobby.host_id == socket.assigns.user.id
        can_join? = not Enum.any?(lobby.users, &(&1.id == socket.assigns.user.id))
        {:noreply, assign(socket, lobby: lobby, host?: host?, can_join?: can_join?)}
    end
  end

  @impl true
  def handle_info({:load_messages, link_id}, socket) do
    messages = Golf.Chat.get_messages(link_id)
    {:noreply, stream(socket, :messages, messages, at: 0)}
  end

  @impl true
  def handle_info({:user_joined, new_user}, %{assigns: %{lobby: lobby}} = socket) do
    lobby = %{lobby | users: lobby.users ++ [new_user]}
    can_join? = not Enum.any?(lobby.users, &(&1.id == socket.assigns.user.id))

    {:noreply,
     socket
     |> assign(lobby: lobby, can_join?: can_join?)
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

  @impl true
  def handle_event("submit-chat", %{"content" => content}, socket) do
    {:ok, message} =
      Golf.Chat.Message.new(
        socket.assigns.link_id,
        socket.assigns.user,
        content
      )
      |> Golf.Chat.insert_message()

    {:noreply, stream_insert(socket, :messages, message)}
  end
end
