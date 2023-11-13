defmodule Golf.Games.Event do
  use Golf.Schema
  import Ecto.Changeset

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

  def new(round_id, player_id, action, hand_index \\ nil) do
    %__MODULE__{
      round_id: round_id,
      player_id: player_id,
      action: action,
      hand_index: hand_index
    }
  end
end
