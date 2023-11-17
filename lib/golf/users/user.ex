defmodule Golf.Users.User do
  use Golf.Schema
  import Ecto.Changeset
  alias Golf.Lobbies.{Lobby, LobbyUser}

  schema "users" do
    field :name, :string
    many_to_many :lobbies, Lobby, join_through: LobbyUser
    timestamps()
  end

  @spec changeset(%__MODULE__{}, map) :: Ecto.Changeset.t()
  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
