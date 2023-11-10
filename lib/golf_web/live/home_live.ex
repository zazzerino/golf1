defmodule GolfWeb.HomeLive do
  use GolfWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Home</h2>
    <p>Hello <%= @user.name %>(<%= @user.id %>)</p>

    <.button phx-click="create_game">
      Create Game
    </.button>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Home")}
  end

  @impl true
  def handle_event("create_game", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/games/opts")}
  end
end
