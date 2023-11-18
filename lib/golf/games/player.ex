defmodule Golf.Games.Player do
  use Golf.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          game_id: Ecto.UUID,
          user_id: integer,
          turn: integer
        }

  @derive {Jason.Encoder, only: [:id, :turn, :position, :heldCard, :hand, :score]}
  schema "players" do
    belongs_to :game, Golf.Games.Game, type: :binary_id
    belongs_to :user, Golf.Users.User
    has_many :events, Golf.Games.Event
    field :turn, :integer
    timestamps()

    field :position, :string, virtual: true
    field :heldCard, :string, virtual: true
    field :hand, {:array, :map}, virtual: true
    field :score, :integer, virtual: true
  end

  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(player, attrs \\ %{}) do
    player
    |> cast(attrs, [:user_id, :game_id, :turn])
    |> validate_required([:user_id, :game_id, :turn])
  end
end
