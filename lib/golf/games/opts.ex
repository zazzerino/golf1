defmodule Golf.Games.Opts do
  use Golf.Schema
  import Ecto.Changeset

  schema "opts" do
    belongs_to :game, Golf.Games.Game
    field :num_rounds, :integer, default: 1
    timestamps()
  end

  def changeset(opts, attrs \\ %{}) do
    opts
    |> cast(attrs, [:num_rounds])
    |> validate_required([:num_rounds])
  end
end
