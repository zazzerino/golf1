defmodule GolfWeb.HomeLive do
  use GolfWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Home</h2>
    <p>Hello <%= @user.name %>(id=<%= @user.id %>)</p>
    <.button class="mt-4 mb-4" phx-click="create-game">
      Create Game
    </.button>
    <form phx-submit="join-game">
      <.input name="game-id" label="Game ID" value="" required />
      <.button>Join Game</.button>
    </form>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Home")}
  end

  @impl true
  def handle_event("create-game", _params, socket) do
    id = Ecto.UUID.generate()
    {:noreply, push_navigate(socket, to: ~p"/games/new/#{id}")}
  end

  @impl true
  def handle_event("join-game", %{"game-id" => id}, socket) do
    with {:ok, id} <- Ecto.UUID.cast(id),
         true <- Golf.Games.game_exists?(id) do
      {:noreply, socket}
    else
      _ ->
        {:noreply, socket |> put_flash(:error, "Game #{id} not found.")}
    end
  end
end
