defmodule Golf.Games.Game do
  use Golf.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, []}

  schema "games" do
    belongs_to :host, Golf.Users.User
    has_one :opts, Golf.Games.Opts
    has_many :players, Golf.Games.Player
    has_many :rounds, Golf.Games.Round
    timestamps()
  end

  def changeset(game, attrs \\ %{}) do
    game
    |> cast(attrs, [:id, :host_id])
    |> validate_required([:id, :host_id])
  end
end
