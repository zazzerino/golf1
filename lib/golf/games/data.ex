defmodule Golf.Games.Data do
  @moduledoc """
  The game data that will be sent to the client.
  """

  alias Golf.Games

  @derive Jason.Encoder
  defstruct [
    :id,
    :state,
    :turn,
    :deck,
    :tableCards,
    :isFlipped,
    :players,
    :playerId,
    :playableCards
  ]

  def from(game, user_id) do
    index = Enum.find_index(game.players, &(&1.user_id == user_id))
    player = if index, do: Enum.at(game.players, index)

    num_players = length(game.players)
    positions = hand_positions(num_players)

    round = Games.current_round(game)
    hands = if round, do: Golf.maybe_rotate(round.hands, index), else: []
    held_card = if round, do: round.held_card

    playable_cards =
      if player && round do
        Games.playable_cards(round, player, num_players)
      else
        []
      end

    players =
      game.players
      |> Golf.maybe_rotate(index)
      |> Enum.zip_with(hands, &put_hand_score/2)
      |> Enum.zip_with(positions, &Map.put(&1, :position, &2))
      |> Enum.map(&Map.put(&1, :username, &1.user.name))
      |> Enum.map(&put_held_card(&1, held_card))

    %__MODULE__{
      id: game.id,
      state: round && round.state,
      isFlipped: round && round.flipped?,
      turn: round && round.turn,
      deck: (round && round.deck) || [],
      tableCards: (round && round.table_cards) || [],
      players: players,
      playerId: player && player.id,
      playableCards: playable_cards
    }
  end

  defp hand_positions(num_players) do
    case num_players do
      1 -> ~w(bottom)
      2 -> ~w(bottom top)
      3 -> ~w(bottom left right)
      4 -> ~w(bottom left top right)
    end
  end

  def put_hand_score(player, nil) do
    %{player | hand: [], score: 0}
  end

  def put_hand_score(player, hand) do
    %{player | hand: hand, score: Games.score(hand)}
  end

  defp put_held_card(player, %{"player_id" => card_id} = card)
       when player.id == card_id do
    %{player | heldCard: card["name"]}
  end

  defp put_held_card(player, _), do: player
end
