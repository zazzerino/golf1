defmodule GolfWeb.GameOptsLive do
  use GolfWeb, :live_view
  alias Golf.Games

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Game Options</h2>

    <form phx-submit="create_game">
      <div>
        <.input label="Number of rounds" name="num_rounds" type="number" min="1" value="1" />
      </div>
      <.button type="submit">Start</.button>
    </form>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("create_game", %{"num_rounds" => num_rounds}, socket) do
    {num_rounds, _} = Integer.parse(num_rounds)

    {:ok, game} =
      Games.create_game(socket.assigns.user.id, num_rounds)
      |> Games.Db.upsert_game()

    {:noreply, redirect(socket, to: ~p"/games/#{game.id}")}
  end
end
