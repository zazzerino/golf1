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
    positions = hand_positions(length(game.players))
    player_index = Enum.find_index(game.players, &(&1.user_id == user_id))
    player = player_index && Enum.at(game.players, player_index)

    round = Golf.Games.current_round(game)
    hands = round && round.hands

    players =
      game.players
      |> maybe_rotate(player_index)
      |> put_positions(positions)
      |> maybe_put_hands(hands)
      |> maybe_put_held_card(round && round.held_card)

    playable_cards =
      if player do
        Golf.Games.playable_cards(game, player.turn)
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
    Enum.zip_with(players, hands, fn player, hand ->
      %{player | hand: hand}
    end)
  end

  defp put_positions(players, positions) do
    Enum.zip_with(players, positions, fn player, pos ->
      %{player | position: pos}
    end)
  end

  defp maybe_put_held_card(players, nil), do: players

  defp maybe_put_held_card(players, %{"player_id" => player_id, "card" => card}) do
    Enum.map(players, fn p ->
      if p.id == player_id do
        %{p | held_card: card}
      else
        p
      end
    end)
  end
end
