defmodule Golf.Lobbies.Lobby do
  import Ecto.Changeset
  use Golf.Schema
  alias Golf.Users.User

  @primary_key {:id, Ecto.UUID, []}

  schema "lobbies" do
    belongs_to :host, User
    many_to_many :users, User, join_through: Golf.Lobbies.LobbyUser
    timestamps()
  end

  def changeset(lobby, attrs \\ %{}) do
    lobby
    |> cast(attrs, [:id, :host_id])
    |> validate_required([:id, :host_id])
  end
end
