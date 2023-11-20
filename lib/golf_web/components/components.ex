defmodule GolfWeb.Components do
  use Phoenix.Component
  import GolfWeb.CoreComponents

  def join_lobby_form(assigns) do
    ~H"""
    <.simple_form for={%{}} phx-submit="join-lobby">
      <.input name="id" label="Game ID" value="" required />
      <:actions>
        <.button>Join Game</.button>
      </:actions>
    </.simple_form>
    """
  end

  def username_form(assigns) do
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
    <div class="mt-6 overflow-y-auto max-h-[350px]">
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
            class="divide-x hover:cursor-pointer hover:bg-zinc-50"
          >
            <td><%= link.id %></td>
            <td><%= link.inserted_at %></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  def opts_form(assigns) do
    ~H"""
    <div>
      <h4 class="font-bold">Settings</h4>
      <.simple_form for={%{}} phx-submit="start-game">
        <.input name="num-rounds" type="number" min="1" max="99" value="1" label="Number of rounds" />
        <:actions>
          <.button>Start Game</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def chat(assigns) do
    ~H"""
    <div class="border-solid">
      <.chat_messages messages={@messages} />
      <.chat_form submit={@submit} />
    </div>
    """
  end

  def chat_messages(assigns) do
    ~H"""
    <div class="mt-4">
      <h4 class="font-bold">Chat</h4>
      <ul id="chat-messages" phx-update="stream">
        <li :for={{id, msg} <- @messages} id={id}>
          <%= msg.content %>
        </li>
      </ul>
    </div>
    """
  end

  def chat_form(assigns) do
    ~H"""
    <form class="space-y-1" phx-submit={@submit}>
      <.input name="content" value="" placeholder="Type chat message here..." required />
      <.button>Submit</.button>
    </form>
    """
  end

  def player_score(assigns) do
    ~H"""
    <div class={"player-score #{@player.position}"}>
      <%= @player.username %>(score=<%= @player.score %>)
    </div>
    """
  end
end
