defmodule Golf.Games.Event do
  use Golf.Schema
  import Ecto.Changeset
  alias Golf.Games.{Game, Round}

  @type action :: :take_from_deck | :take_from_table | :swap | :discard | :flip

  @actions [:take_from_deck, :take_from_table, :swap, :discard, :flip]

  @derive {Jason.Encoder, only: [:round_id, :player_id, :action, :hand_index]}
  schema "events" do
    belongs_to :round, Golf.Games.Round
    belongs_to :player, Golf.Games.Player
    field :action, Ecto.Enum, values: @actions
    field :hand_index, :integer
    timestamps(updated_at: false)
  end

  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [:round_id, :player_id, :action, :hand_index])
    |> validate_required([:round_id, :player_id, :action])
  end

  def new(game_or_round, player, action, hand_index \\ nil)

  def new(%Game{rounds: [round | _]}, player, action, hand_index) do
    new(round, player, action, hand_index)
  end

  def new(%Round{} = round, player, action, hand_index) do
    %__MODULE__{
      round_id: round.id,
      player_id: player.id,
      player: player,
      action: action,
      hand_index: hand_index
    }
  end
end
