defmodule GolfWeb.UserLive do
  use GolfWeb, :live_view
  import GolfWeb.Components, only: [username_form: 1, links_table: 1]
  alias Golf.Users.User

  @impl true
  def render(assigns) do
    ~H"""
    <h2 class="font-bold text-2xl mb-2">User</h2>
    <div class="mb-2">User(id=<%= @user.id %>, name=<%= @user.name %>)</div>
    <.username_form form={@name_form} />
    <.links_table :if={@links != []} links={@links} />
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{user: user}} = socket) do
    if connected?(socket) do
      send(self(), :load_links)
    end

    {:ok,
     assign(socket,
       page_title: "User",
       user: user,
       name_form: to_form(User.changeset(user)),
       links: []
     )}
  end

  @impl true
  def handle_info(:load_links, socket) do
    links =
      Golf.Users.get_links(socket.assigns.user.id)
      |> Enum.map(&format_link/1)

    {:noreply, assign(socket, links: links)}
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
  def handle_event("update-name", %{"user" => %{"name" => name}}, socket)
      when name == socket.assigns.user.name do
    {:noreply, put_flash(socket, :error, "Username not changed.")}
  end

  @impl true
  def handle_event("update-name", %{"user" => params}, socket) do
    {:ok, user} = Golf.Users.update_user(socket.assigns.user, params)

    {:noreply,
     socket
     |> assign(user: user, name_form: to_form(User.changeset(user)))
     |> put_flash(:info, "Username updated.")}
  end

  @impl true
  def handle_event("link-row-click", %{"link" => link}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/game/#{link}")}
  end

  defp format_link(link) do
    Map.update!(link, :inserted_at, fn dt -> Golf.format_time(dt) end)
  end
end

# def links_table(assigns) do
#   ~H"""
#   <.table id="links-table" rows={@links} row_click={fn _ -> "link-row-click" end}>
#     <:col :let={link} label="ID">
#       <%= link.id %>
#     </:col>
#   </.table>
#   """
# end
