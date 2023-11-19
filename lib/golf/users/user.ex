defmodule Golf.Users.User do
  use Golf.Schema
  import Ecto.Changeset

  alias Golf.Lobbies.{Lobby, LobbyUser}

  schema "users" do
    field :name, :string
    many_to_many :lobbies, Lobby, join_through: LobbyUser
    timestamps()
  end

  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def name_changeset(%__MODULE__{} = new, attrs, user) do
    new
    |> changeset(attrs)
    |> validate_name_change(user)
  end

  defp validate_name_change(changeset, user) do
    if changeset.changes[:name] == user.name do
      Ecto.Changeset.add_error(changeset, :name, "not changed")
    else
      changeset
    end
  end
end
