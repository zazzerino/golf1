defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Game <%= @game_id %></h2>

    <div>
      <div id="game-canvas" phx-hook="GameCanvas" phx-update="ignore"></div>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    with {id, _} <- Integer.parse(id) do
      if connected?(socket) do
        send(self(), {:load_game, id})
      end

      {:ok, assign(socket, page_title: "Game #{id}", game_id: id)}
    else
      _ ->
        {:ok,
         socket
         |> redirect(to: ~p"/")
         |> put_flash(:error, "#{id} is not a valid game id.")}
    end
  end

  @impl true
  def handle_info({:load_game, id}, socket) do
    case Golf.GamesDb.get_game(id) do
      nil ->
        {:noreply, socket |> redirect(to: ~p"/") |> put_flash(:error, "Game #{id} not found.")}

      game ->
        :ok = subscribe(id)
        {:noreply, assign(socket, game: game)}
    end
  end

  defp subscribe(game_id) do
    Phoenix.PubSub.subscribe(Golf.PubSub, "game:#{game_id}")
  end

  defp broadcast(game_id, msg) do
    Phoenix.PubSub.broadcast(Golf.PubSub, "game:#{game_id}", msg)
  end
end
