defmodule GolfWeb.GameController do
  use GolfWeb, :controller

  def join(conn, %{"id" => id}) do
    with lobby when is_struct(lobby) <- Golf.Games.get_lobby(id) do
      dbg(lobby)
      redirect(conn, to: ~p"/lobby/#{id}")
    else
      _ ->
        redirect(conn, to: ~p"/")
    end
  end
end
