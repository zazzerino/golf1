defmodule Golf.Games do
  alias Golf.Games.{Game, Event, Player, Round}

  @card_names for rank <- ~w(A 2 3 4 5 6 7 8 9 T J Q K),
                  suit <- ~w(C D H S),
                  do: rank <> suit

  @num_decks 2
  @hand_size 6

  defguard is_state(game, state) when hd(game.rounds).state == state

  def create_game(host_id, num_rounds) do
    player = %Player{user_id: host_id, turn: 0}

    %Game{
      host_id: host_id,
      num_rounds: num_rounds,
      players: [player],
      rounds: []
    }
  end

  def add_player(game, user_id) do
    next_turn = length(game.players)
    player = %Player{game_id: game.id, user_id: user_id, turn: next_turn}
    %Game{game | players: game.players ++ [player]}
  end

  def start_next_round(game) do
    deck = new_deck(@num_decks) |> Enum.shuffle()

    # deal hands
    num_cards = @hand_size * length(game.players)
    {:ok, cards, deck} = deal_from_deck(deck, num_cards)

    hands =
      cards
      |> Enum.map(fn card -> %{"name" => card, "face_up?" => false} end)
      |> Enum.chunk_every(@hand_size)

    # deal table card
    {:ok, card, deck} = deal_from_deck(deck)

    round = %Round{
      game_id: game.id,
      state: :flip_2,
      turn: 0,
      deck: deck,
      hands: hands,
      table_cards: [card],
      events: []
    }

    %Game{game | rounds: [round | game.rounds]}
  end

  def handle_event(game, %Event{action: :flip} = event) when is_state(game, :flip_2) do
    round = hd(game.rounds)
    index = get_player_index(game, event.player_id)
    hand = Enum.at(round.hands, index)

    if num_cards_face_up(hand) < 2 do
      hands =
        List.update_at(round.hands, index, fn hand ->
          flip_card(hand, event.hand_index)
        end)

      all_done_flipping? =
        Enum.all?(hands, fn hand ->
          num_cards_face_up(hand) >= 2
        end)

      {state, turn} =
        if all_done_flipping? do
          {:take, round.turn + 1}
        else
          {:flip_2, round.turn}
        end

      rounds =
        List.update_at(game.rounds, 0, fn r ->
          %Round{r | state: state, turn: turn, hands: hands, events: [event | round.events]}
        end)

      {:ok, %Game{game | rounds: rounds}}
    else
      {:error, :already_flipped}
    end
  end

  def playable_cards(_game, _player_id) do
    []
  end

  defp flip_card(hand, index) do
    List.update_at(hand, index, fn card ->
      %{card | "face_up?" => true}
    end)
  end

  defp num_cards_face_up(hand) do
    Enum.count(hand, fn card -> card["face_up?"] end)
  end

  defp get_player_index(game, player_id) do
    game.players
    |> Enum.find_index(&(&1.id == player_id))
  end

  defp new_deck(1), do: @card_names

  defp new_deck(n) when n > 1 do
    @card_names ++ new_deck(n - 1)
  end

  defp deal_from_deck([], _) do
    {:error, :empty_deck}
  end

  defp deal_from_deck(deck, n) when length(deck) < n do
    {:error, :not_enough_cards}
  end

  defp deal_from_deck(deck, n) do
    {cards, deck} = Enum.split(deck, n)
    {:ok, cards, deck}
  end

  defp deal_from_deck(deck) do
    with {:ok, [card], deck} <- deal_from_deck(deck, 1) do
      {:ok, card, deck}
    end
  end
end
