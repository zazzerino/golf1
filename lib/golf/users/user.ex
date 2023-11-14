defmodule Golf.Users.User do
  use Golf.Schema
  import Ecto.Changeset

  # @type t :: %__MODULE__{
  #         id: integer,
  #         name: String.t(),
  #         lobbies: any,
  #         inserted_at: any,
  #         updated_at: any
  #       }

  schema "users" do
    field :name, :string
    many_to_many :lobbies, Golf.Games.Lobby, join_through: Golf.UserLobby
    timestamps()
  end

  @spec changeset(%__MODULE__{}, map) :: Ecto.Changeset.t()
  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
