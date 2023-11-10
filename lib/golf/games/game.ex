defmodule Golf.Games.Game do
  use Golf.Schema
  import Ecto.Changeset

  schema "games" do
    belongs_to :host, Golf.Users.User
    field :num_rounds, :integer
    has_many :players, Golf.Games.Player
    has_many :rounds, Golf.Games.Round
    timestamps()
  end

  def changeset(game, attrs \\ %{}) do
    game
    |> cast(attrs, [:host_id, :num_rounds])
    |> validate_required([:host_id, :num_rounds])
  end
end
