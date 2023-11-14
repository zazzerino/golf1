defmodule Golf.Games.Round do
  use Golf.Schema
  import Ecto.Changeset

  @states [:init, :flip_2, :take, :hold, :flip, :last_take, :last_hold, :last_flip, :over]

  @derive {Jason.Encoder, only: [:state, :turn, :deck, :table_cards, :hands, :held_card]}
  schema "rounds" do
    belongs_to :game, Golf.Games.Game, type: :binary_id

    field :state, Ecto.Enum, values: @states
    field :turn, :integer
    field :deck, {:array, :string}, default: []
    field :table_cards, {:array, :string}, default: []
    field :hands, {:array, {:array, :map}}, default: []
    field :held_card, :map

    has_many :events, Golf.Games.Event

    field :num_players, :integer, virtual: true
    timestamps()
  end

  def changeset(round, attrs \\ %{}) do
    round
    |> cast(attrs, [:game_id, :state, :turn, :deck, :table_cards, :hands, :held_card])
    |> validate_required([:game_id, :state, :turn, :deck, :table_cards, :hands])
  end
end
