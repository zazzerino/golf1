defmodule Golf.Games.Data do
  @moduledoc """
  The game data that will be sent to the client.
  """

  @derive Jason.Encoder
  defstruct [
    :id,
    :state,
    :isFlipped,
    :turn,
    :deck,
    :tableCards,
    :players,
    :playerId,
    :playableCards
  ]

  def from(game, user_id) do
    num_players = length(game.players)
    index = Enum.find_index(game.players, &(&1.user_id == user_id))
    player = index && Enum.at(game.players, index)
    positions = hand_positions(num_players)
    round = Golf.Games.current_round(game)
    hands = if round, do: maybe_rotate(round.hands, index)

    players =
      game.players
      |> maybe_rotate(index)
      |> put_positions(positions)
      |> put_hands(hands)
      |> put_held_card(round && round.held_card)

    playable_cards =
      if round && player do
        Golf.Games.playable_cards(round, player, num_players)
      else
        []
      end

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

  defp maybe_rotate(list, n) when n in [0, nil], do: list

  defp maybe_rotate(list, n) do
    list
    |> Stream.cycle()
    |> Stream.drop(n)
    |> Stream.take(length(list))
    |> Enum.to_list()
  end

  defp put_hands(players, nil), do: players

  defp put_hands(players, hands) do
    Enum.zip_with(players, hands, fn p, hand -> %{p | hand: hand} end)
  end

  defp put_positions(players, positions) do
    Enum.zip_with(players, positions, fn p, pos -> %{p | position: pos} end)
  end

  defp put_held_card(players, nil), do: players

  defp put_held_card(players, %{"player_id" => player_id, "name" => card}) do
    Enum.map(players, &do_put_held(&1, player_id, card))
  end

  defp do_put_held(%{id: id} = player, player_id, card) when id == player_id do
    %{player | heldCard: card}
  end

  defp do_put_held(player, _, _), do: player
end
