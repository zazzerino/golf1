defmodule Golf.Games.Lobby do
  import Ecto.Changeset
  use Golf.Schema

  @primary_key {:id, Ecto.UUID, []}

  schema "lobbies" do
    belongs_to :host, Golf.Users.User
    many_to_many :users, Golf.Users.User, join_through: Golf.UserLobby
    timestamps()
  end

  def changeset(lobby, attrs \\ %{}) do
    lobby
    |> cast(attrs, [:id, :host_id])
    |> validate_required([:id, :host_id])
  end
end
