defmodule Golf.Games.Player do
  use Golf.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :turn, :position, :heldCard, :hand, :score, :username]}
  schema "players" do
    belongs_to :game, Golf.Games.Game
    belongs_to :user, Golf.Users.User
    has_many :events, Golf.Games.Event

    field :turn, :integer
    timestamps()

    field :position, :string, virtual: true
    field :heldCard, :string, virtual: true
    field :hand, {:array, :map}, virtual: true
    field :score, :integer, virtual: true
    field :username, :string, virtual: true
  end

  def changeset(player, attrs \\ %{}) do
    player
    |> cast(attrs, [:game_id, :user_id, :turn])
    |> validate_required([:game_id, :user_id, :turn])
  end
end
