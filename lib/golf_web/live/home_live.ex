defmodule GolfWeb.HomeLive do
  use GolfWeb, :live_view

  @link_length 6

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Home</h2>
    <p>Hello <%= @user.name %>(id=<%= @user.id %>)</p>

    <.button class="my-2" phx-click="create-lobby">
      Create Game
    </.button>

    <.join_form />
    """
  end

  defp join_form(assigns) do
    ~H"""
    <.simple_form for={%{}} phx-submit="join-lobby">
      <.input name="id" label="Game ID" value="" required />
      <:actions>
        <.button>Join Game</.button>
      </:actions>
    </.simple_form>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Home")}
  end

  @impl true
  def handle_event("create-lobby", _params, socket) do
    {:ok, {link_id, _}} = Golf.Links.create_link_lobby(socket.assigns.user)
    {:noreply, push_navigate(socket, to: ~p"/lobby/#{link_id}")}
  end

  @impl true
  def handle_event("join-game", %{"id" => link_id}, socket)
      when byte_size(link_id) != @link_length do
    {:noreply, put_flash(socket, :error, "Game not found.")}
  end

  @impl true
  def handle_event("join-lobby", %{"id" => link_id}, socket) do
    case Golf.Links.get_lobby(link_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Game #{link_id} not found.")}

      lobby ->
        {:ok, _} = Golf.Lobbies.add_lobby_user(lobby, socket.assigns.user)
        :ok = Golf.broadcast("lobby:#{lobby.id}", {:user_joined, socket.assigns.user})
        {:noreply, push_navigate(socket, to: ~p"/lobby/#{link_id}")}
    end
  end
end
