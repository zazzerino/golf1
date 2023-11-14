defmodule Golf.Games.Data do
  @moduledoc """
  The game data that will be sent to the client.
  """

  @derive Jason.Encoder
  defstruct [
    :id,
    :state,
    :turn,
    :deck,
    :tableCards,
    :players,
    :playerId,
    :playableCards
  ]

  def from(game, user_id) do
    index = Enum.find_index(game.players, &(&1.user_id == user_id))
    player = index && Enum.at(game.players, index)
    positions = hand_positions(length(game.players))
    round = Golf.Games.current_round(game)

    players =
      game.players
      |> maybe_rotate(index)
      |> put_positions(positions)
      |> maybe_put_hands(round && round.hands)
      |> maybe_put_held_card(round && round.held_card)

    playable_cards =
      if index do
        Golf.Games.playable_cards(game, index)
      else
        []
      end

    %__MODULE__{
      id: game.id,
      state: round && round.state,
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

  # don't do anything if n is 0 or nil
  defp maybe_rotate(list, 0), do: list
  defp maybe_rotate(list, nil), do: list

  # otherwise rotate the list n elements
  defp maybe_rotate(list, n) do
    list
    |> Stream.cycle()
    |> Stream.drop(n)
    |> Stream.take(length(list))
    |> Enum.to_list()
  end

  defp maybe_put_hands(players, nil), do: players

  defp maybe_put_hands(players, hands) do
    Enum.zip_with(players, hands, fn p, hand -> %{p | hand: hand} end)
  end

  defp put_positions(players, positions) do
    Enum.zip_with(players, positions, fn p, pos -> %{p | position: pos} end)
  end

  defp maybe_put_held_card(players, nil), do: players

  defp maybe_put_held_card(players, %{"player_id" => player_id, "card" => card}) do
    Enum.map(players, &put_held(&1, player_id, card))
  end

  defp put_held(%{id: id} = p, p_id, card) when id == p_id, do: %{p | heldCard: card}
  defp put_held(player, _, _), do: player
end
