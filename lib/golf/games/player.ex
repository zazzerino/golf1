defmodule Golf.Games.Player do
  use Golf.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :turn, :position, :heldCard, :hand]}
  schema "players" do
    belongs_to :game, Golf.Games.Game, type: :binary_id
    belongs_to :user, Golf.Users.User
    field :turn, :integer
    has_many :events, Golf.Games.Event
    timestamps()

    field :position, :string, virtual: true
    field :heldCard, :string, virtual: true
    field :hand, {:array, :map}, virtual: true
  end

  def changeset(player, attrs \\ %{}) do
    player
    |> cast(attrs, [:user_id, :game_id, :turn])
    |> validate_required([:user_id, :game_id, :turn])
  end
end
