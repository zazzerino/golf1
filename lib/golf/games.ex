defmodule Golf.Games do
  import Ecto.Query
  alias Golf.Repo
  alias Golf.Users.User
  alias Golf.Games.{Game, Event, Player, Round, Opts}

  @card_names for rank <- ~w(A 2 3 4 5 6 7 8 9 T J Q K),
                  suit <- ~w(C D H S),
                  do: rank <> suit

  @num_decks 2
  @hand_size 6

  def get_game(id) do
    events_query = from(e in Event, order_by: [desc: :id])
    players_query = from(p in Player, order_by: p.turn)

    Repo.get(Game, id)
    |> Repo.preload([:opts, rounds: [events: events_query], players: players_query])
  end

  def game_exists?(id) do
    from(g in Game, where: [id: ^id])
    |> Repo.exists?()
  end

  def create_game(id, %User{id: host_id}, opts \\ %Opts{}) do
    player = %Player{user_id: host_id, turn: 0}

    %Game{
      id: id,
      host_id: host_id,
      opts: opts,
      players: [player],
      rounds: []
    }
    |> Game.changeset()
    |> Repo.insert()
  end

  def add_player(game, %User{id: user_id}) when game.rounds == [] do
    next_turn = length(game.players)

    {:ok, player} =
      %Player{game_id: game.id, user_id: user_id, turn: next_turn}
      |> Player.changeset()
      |> Repo.insert()

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

    {:ok, round} =
      %Round{
        game_id: game.id,
        state: :flip_2,
        turn: 0,
        deck: deck,
        hands: hands,
        table_cards: [card],
        events: []
      }
      |> Round.changeset()
      |> Repo.insert()

    {:ok, %Game{game | rounds: [round | game.rounds]}}
  end

  def current_round(%Game{rounds: [round | _]}), do: round
  def current_round(_), do: nil

  def players_turn?(%Game{rounds: []}, _), do: false

  def players_turn?(%Game{rounds: [%Round{state: :flip_2, hands: hands} | _]}, turn) do
    hand = Enum.at(hands, turn)
    num_cards_face_up(hand) < 2
  end

  def players_turn?(%Game{rounds: [round | _]} = game, turn) do
    rem(round.turn, length(game.players)) == turn
  end

  def handle_event(
        %Game{rounds: [%Round{state: :flip_2} = round | _]} = game,
        %Event{action: :flip} = event
      ) do
    Repo.transaction(fn ->
      index = Enum.find_index(game.players, &(&1.id == event.player_id))

      hands =
        List.update_at(round.hands, index, fn hand ->
          flip_card(hand, event.hand_index)
        end)

      all_done_flipping? = Enum.all?(hands, &(num_cards_face_up(&1) >= 2))
      state = if all_done_flipping?, do: :take, else: :flip_2

      {:ok, event} = Repo.insert(Event.changeset(event))

      rounds =
        List.update_at(game.rounds, 0, fn r ->
          {:ok, round} =
            Round.changeset(r, %{state: state, hands: hands})
            |> Repo.update()

          %Round{round | events: [event | round.events]}
        end)

      %Game{game | rounds: rounds}
    end)
  end

  def handle_event(
        %Game{rounds: [%Round{state: :take} = round | _]} = game,
        %Event{action: :take_from_deck} = event
      ) do
    Repo.transaction(fn ->
      {:ok, card, deck} = deal_from_deck(round.deck)
      {:ok, event} = Repo.insert(Event.changeset(event))

      rounds =
        List.update_at(game.rounds, 0, fn r ->
          {:ok, round} =
            Round.changeset(r, %{
              status: :hold,
              deck: deck,
              held_card: %{"player_id" => event.player_id, "card" => card}
            })
            |> Repo.update()

          %Round{round | events: [event | round.events]}
        end)

      %Game{game | rounds: rounds}
    end)
  end

  def playable_cards(%Game{rounds: [%Round{state: :flip_2, hands: hands} | _]}, turn) do
    hand = Enum.at(hands, turn)

    if num_cards_face_up(hand) < 2 do
      face_down_cards(hand)
    else
      []
    end
  end

  def playable_cards(%Game{rounds: [%Round{state: :flip, hands: hands}]} = game, turn) do
    if players_turn?(game, turn) do
      Enum.at(hands, turn)
      |> face_down_cards()
    else
      []
    end
  end

  def playable_cards(%Game{rounds: [%Round{state: :last_take, hands: hands} | _]} = game, turn) do
    if players_turn?(game, turn) do
      hand = Enum.at(hands, turn)
      [:deck, :table] ++ face_down_cards(hand)
    else
      []
    end
  end

  def playable_cards(%Game{rounds: [%Round{state: :take} | _]} = game, turn) do
    if players_turn?(game, turn) do
      [:deck, :table]
    else
      []
    end
  end

  def playable_cards(%Game{rounds: [round | _]} = game, turn)
      when round.state in [:hold, :last_hold] do
    if players_turn?(game, turn) do
      [:held, :hand_0, :hand_1, :hand_2, :hand_3, :hand_4, :hand_5]
    else
      []
    end
  end

  def playable_cards(_, _), do: []

  defp flip_card(hand, index) do
    List.update_at(hand, index, fn card ->
      %{card | "face_up?" => true}
    end)
  end

  defp num_cards_face_up(hand) do
    Enum.count(hand, fn card -> card["face_up?"] end)
  end

  defp face_down_cards(hand) do
    hand
    |> Enum.with_index()
    |> Enum.reject(fn {card, _} -> card["face_up?"] end)
    |> Enum.map(fn {_, index} -> String.to_atom("hand_#{index}") end)
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

# @card_positions [:deck, :table, :held, :hand_0, :hand_1, :hand_2, :hand_3, :hand_4, :hand_5]

# # https://gist.github.com/danschultzer/99c21ba403fd7f49a26cc40571ff5cce
# def gen_id() do
#   min = String.to_integer("100000", 36)
#   max = String.to_integer("ZZZZZZ", 36)

#   max
#   |> Kernel.-(min)
#   |> :rand.uniform()
#   |> Kernel.+(min)
#   |> Integer.to_string(36)
# end
