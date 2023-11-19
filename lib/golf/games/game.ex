defmodule Golf.Games.Game do
  use Golf.Schema
  import Ecto.Changeset

  schema "games" do
    belongs_to :host, Golf.Users.User
    has_one :opts, Golf.Games.Opts
    has_many :players, Golf.Games.Player
    has_many :rounds, Golf.Games.Round
    timestamps()
  end

  def changeset(game, attrs \\ %{}) do
    game
    |> cast(attrs, [:host_id])
    |> validate_required([:host_id])
  end
end
