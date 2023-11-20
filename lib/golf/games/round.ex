defmodule Golf.Games.Round do
  use Golf.Schema
  import Ecto.Changeset

  @states [:flip_2, :take, :hold, :flip, :round_over]

  schema "rounds" do
    belongs_to :game, Golf.Games.Game
    has_many :events, Golf.Games.Event

    field :state, Ecto.Enum, values: @states
    field :turn, :integer
    field :deck, {:array, :string}, default: []
    field :table_cards, {:array, :string}, default: []
    field :hands, {:array, {:array, :map}}, default: []
    field :held_card, :map
    field :flipped?, :boolean, default: false

    timestamps()
  end

  def changeset(round, attrs \\ %{}) do
    round
    |> cast(attrs, [:game_id, :state, :turn, :deck, :table_cards, :hands, :held_card, :flipped?])
    |> validate_required([:game_id, :state, :turn, :deck, :table_cards, :hands, :flipped?])
  end
end
