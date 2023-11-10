defmodule Golf.Games.Player do
  use Golf.Schema
  import Ecto.Changeset

  schema "players" do
    belongs_to :user, Golf.Users.User
    belongs_to :game, Golf.Games.Game
    field :turn, :integer
    has_many :events, Golf.Games.Event
    timestamps()
  end

  def changeset(player, attrs \\ %{}) do
    player
    |> cast(attrs, [:user_id, :game_id, :turn])
    |> validate_required([:user_id, :game_id, :turn])
  end
end
