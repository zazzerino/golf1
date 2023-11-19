defmodule Golf.Lobbies.LobbyUser do
  use Golf.Schema
  import Ecto.Changeset

  @primary_key false

  schema "lobbies_users" do
    belongs_to :lobby, Golf.Lobbies.Lobby
    belongs_to :user, Golf.Users.User
    timestamps()
  end

  def changeset(lobby_user, attrs \\ %{}) do
    lobby_user
    |> cast(attrs, [:lobby_id, :user_id])
    |> validate_required([:lobby_id, :user_id])
  end
end
