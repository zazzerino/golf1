defmodule GolfWeb.UserLive do
  use GolfWeb, :live_view
  alias Golf.Users.User

  @impl true
  def render(assigns) do
    ~H"""
    <h2 class="font-bold mb-2">User Settings</h2>
    <div>User(id=<%= @user.id %>)</div>
    <.username_form form={@name_form} />
    <.links_table :if={@links != []} links={@links} />
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

  def links_table(assigns) do
    ~H"""
    <div class="mt-4 overflow-y-auto max-h-[350px]">
      <h3 class="font-bold mb-2">Games</h3>
      <table class="w-[20rem]">
        <thead class="text-sm text-left">
          <tr>
            <th>ID</th>
            <th>Created At</th>
          </tr>
        </thead>
        <tbody class="text-left divide-y">
          <tr
            :for={link <- @links}
            phx-click="link-row-click"
            phx-value-link={link.id}
            class="divide-x hover:cursor-pointer"
          >
            <td><%= link.id %></td>
            <td><%= link.inserted_at %></td>
          </tr>
        </tbody>
      </table>
    </div>
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
      socket.assigns.user.id
      |> Golf.Users.get_links()
      |> Enum.map(&Map.take(&1, [:id, :inserted_at]))
      |> Enum.map(&Map.update!(&1, :inserted_at, fn dt -> Golf.format_time(dt) end))

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

  @impl true
  def handle_event("link-row-click", %{"link" => link}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/game/#{link}")}
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
