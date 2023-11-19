defmodule GolfWeb.UserLive do
  use GolfWeb, :live_view
  alias Golf.Users.User

  @impl true
  def render(assigns) do
    ~H"""
    <h2>User Settings</h2>
    <div>User(id=<%= @user.id %>)</div>
    <.username_form form={@name_form} />
    """
  end

  defp username_form(assigns) do
    ~H"""
    <.simple_form for={@form} phx-change="validate-name" phx-submit="update-name">
      <.input field={@form[:name]} label="Name" required />
      <:actions>
        <.button>Save</.button>
      </:actions>
    </.simple_form>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{user: user}} = socket) do
    {:ok,
     assign(socket,
       page_title: "User",
       user: user,
       name_form: to_form(User.changeset(user))
     )}
  end

  @impl true
  def handle_event("validate-name", %{"user" => params}, socket) do
    form =
      %User{}
      |> User.name_changeset(params, socket.assigns.user)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, name_form: form)}
  end

  @impl true
  def handle_event(
        "update-name",
        %{"user" => %{"name" => name}},
        %{assigns: %{user: user}} = socket
      )
      when name == user.name do
    {:noreply, put_flash(socket, :error, "Username not changed.")}
  end

  @impl true
  def handle_event(
        "update-name",
        %{"user" => params},
        %{assigns: %{user: user}} = socket
      ) do
    {:ok, user} = Golf.Users.update_user(user, params)

    {:noreply,
     socket
     |> assign(user: user, name_form: to_form(User.changeset(user)))
     |> put_flash(:info, "Username updated.")}
  end
end
