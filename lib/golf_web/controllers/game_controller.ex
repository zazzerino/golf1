defmodule GolfWeb.GameController do
  use GolfWeb, :controller

  def join(conn, %{"id" => id}) do
    with {:ok, id} <- Ecto.UUID.cast(id) do
      redirect(conn, to: ~p"/lobby/#{id}")
    else
      _ ->
        conn
        |> redirect(to: ~p"/")
        |> put_flash(:error, "Game #{id} not found.")
    end
  end
end
