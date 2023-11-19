defmodule GolfWeb.HomeLive do
  use GolfWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Home</h2>
    <p>Hello <%= @user.name %>(id=<%= @user.id %>)</p>

    <.button class="mt-4 mb-4" phx-click="create-lobby">
      Create Game
    </.button>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Home")}
  end

  @impl true
  def handle_event("create-lobby", _params, socket) do
    {:ok, link} = Golf.Links.create_lobby_link(socket.assigns.user)
    {:noreply, push_navigate(socket, to: ~p"/lobby/#{link.id}")}
  end
end
