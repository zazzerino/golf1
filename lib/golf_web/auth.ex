defmodule GolfWeb.Auth do
  import Plug.Conn

  @salt "ZGyQachRbPWdgzkTuLKSoMMUTcCnWSqnxqgaPAdq4nJM8IZ3JthI6GtIMZLzEjri"

  @user_cookie "_golf_user"
  @cookie_opts [same_site: "Lax"]

  def verify_token(token) do
    Phoenix.Token.verify(GolfWeb.Endpoint, @salt, token)
  end

  def put_user_token(conn, _opts) do
    cond do
      # token in session
      token = get_session(conn, :user_token) ->
        assign(conn, :user_token, token)

      # token in cookies
      token = get_user_cookie(conn) ->
        conn
        |> assign(:user_token, token)
        |> put_session(:user_token, token)

      # otherwise, create a new token
      true ->
        {:ok, user} = Golf.Users.insert_user()
        token = Phoenix.Token.sign(GolfWeb.Endpoint, @salt, user.id)

        conn
        |> assign(:user_token, token)
        |> put_session(:user_token, token)
        |> put_resp_cookie(@user_cookie, token, @cookie_opts)
    end
  end

  def on_mount(:default, _params, session, socket) do
    case verify_token(session["user_token"]) do
      {:ok, user_id} ->
        socket =
          Phoenix.Component.assign_new(socket, :user, fn ->
            Golf.Users.get_user(user_id)
          end)

        if socket.assigns.user do
          {:cont, socket}
        else
          {:halt,
           socket
           |> Phoenix.LiveView.redirect(to: "/")
           |> Phoenix.LiveView.put_flash(:error, "User #{user_id} not found.")}
        end

      _ ->
        {:halt,
         socket
         |> Phoenix.LiveView.redirect(to: "/")
         |> Phoenix.LiveView.put_flash(:error, "Invalid user token.")}
    end
  end

  defp get_user_cookie(conn) do
    conn
    |> Map.get(:req_cookies)
    |> Map.get(@user_cookie)
  end
end
