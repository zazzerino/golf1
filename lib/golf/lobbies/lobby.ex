defmodule Golf.Lobbies.Lobby do
  import Ecto.Changeset
  use Golf.Schema
  alias Golf.Users.User

  schema "lobbies" do
    belongs_to :host, User
    many_to_many :users, User, join_through: Golf.Lobbies.LobbyUser
    timestamps()
  end

  def changeset(lobby, attrs \\ %{}) do
    lobby
    |> cast(attrs, [:host_id])
    |> validate_required([:host_id])
  end
end
