defmodule GolfWeb.HomeLive do
  use GolfWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Home</h2>
    <p>Hello <%= @user.name %>(<%= @user.id %>)</p>
    <.button phx-click="create-game">
      Create Game
    </.button>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Home")}
  end

  @impl true
  def handle_event("create-game", _params, socket) do
    opts_id = Golf.gen_id()
    {:noreply, push_navigate(socket, to: ~p"/games/opts/#{opts_id}")}
  end
end
