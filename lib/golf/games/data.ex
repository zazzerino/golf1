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
    turn = if round, do: round.turn
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
      |> put_hands(hands)
      |> Enum.zip_with(positions, &Map.put(&1, :position, &2))
      |> Enum.map(&Map.put(&1, :username, &1.user.name))
      |> Enum.map(&put_held_card(&1, held_card))

    %__MODULE__{
      id: game.id,
      turn: turn,
      state: Games.current_state(game),
      isFlipped: round && round.flipped?,
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

  defp put_hands(players, []) do
    Enum.map(players, fn p -> %{p | hand: [], score: 0} end)
  end

  defp put_hands(players, hands) do
    Enum.zip_with(players, hands, fn p, hand ->
      %{p | hand: hand, score: Games.score(hand)}
    end)
  end

  defp put_held_card(p, %{"player_id" => card_id} = card) when p.id == card_id do
    %{p | heldCard: card["name"]}
  end

  defp put_held_card(player, _), do: player
end
