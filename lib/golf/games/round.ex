defmodule Golf.Games.Round do
  use Golf.Schema
  import Ecto.Changeset

  @states [:flip_2, :take, :hold, :flip, :over]

  schema "rounds" do
    belongs_to :game, Golf.Games.Game, type: :binary_id

    field :state, Ecto.Enum, values: @states
    field :turn, :integer
    field :deck, {:array, :string}, default: []
    field :table_cards, {:array, :string}, default: []
    field :hands, {:array, {:array, :map}}, default: []
    field :held_card, :map
    field :flipped?, :boolean, default: false

    has_many :events, Golf.Games.Event

    field :num_players, :integer, virtual: true
    timestamps()
  end

  def changeset(round, attrs \\ %{}) do
    round
    |> cast(attrs, [:game_id, :state, :turn, :deck, :table_cards, :hands, :held_card, :flipped?])
    |> validate_required([:game_id, :state, :turn, :deck, :table_cards, :hands, :flipped?])
  end
end
