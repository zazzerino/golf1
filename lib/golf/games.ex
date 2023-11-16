defmodule Golf.Games do
  import Ecto.Query

  alias Golf.Repo
  alias Golf.Users.User
  alias Golf.UserLobby
  alias Golf.Games.{Game, Event, Player, Round, Opts, Lobby}

  @type id :: Ecto.UUID.t()
  @type card_name :: binary()

  @card_names for rank <- ~w(A 2 3 4 5 6 7 8 9 T J Q K),
                  suit <- ~w(C D H S),
                  do: rank <> suit

  @num_decks 2
  @hand_size 6

  @max_players 4

  def gen_id(), do: Ecto.UUID.generate()

  @spec get_lobby(id) :: %Lobby{} | nil

  def get_lobby(id) do
    # sort users by the time they joined the lobby
    users_query =
      from(u in User,
        join: ul in UserLobby,
        on: u.id == ul.user_id,
        where: ^id == ul.lobby_id,
        order_by: ul.inserted_at,
        select: u
      )

    Repo.get(Lobby, id)
    |> Repo.preload(users: users_query)
  end

  @spec create_lobby(id, %User{}) :: {:ok, %Lobby{}} | {:error, any}

  def create_lobby(id, host) do
    %Lobby{id: id, host_id: host.id, users: [host]}
    |> Lobby.changeset()
    |> Repo.insert()
  end

  @spec add_lobby_user(%Lobby{}, %User{}) :: {:ok, %Lobby{}} | {:error, any}

  def add_lobby_user(lobby, _) when length(lobby.users) >= @max_players do
    {:error, :max_players}
  end

  def add_lobby_user(lobby, user) do
    if Enum.any?(lobby.users, &(&1.id == user.id)) do
      {:error, :already_joined}
    else
      lobby
      |> Lobby.changeset()
      |> Ecto.Changeset.put_assoc(:users, lobby.users ++ [user])
      |> Repo.update()
    end
  end

  @spec fetch_game(id) :: {:ok, %Game{}} | {:error, any}

  def fetch_game(id) do
    players_query = from(p in Player, order_by: p.turn)
    events_query = from(e in Event, order_by: [desc: :id])

    game =
      Repo.get(Game, id)
      |> Repo.preload([:opts, rounds: [events: {events_query, [:player]}], players: players_query])

    case game do
      nil ->
        {:error, :not_found}

      game ->
        num_players = length(game.players)
        rounds = Enum.map(game.rounds, &%Round{&1 | num_players: num_players})
        {:ok, %Game{game | rounds: rounds}}
    end
  end

  def state(%Game{rounds: []}), do: :no_rounds
  def state(%Game{rounds: [round | _]}), do: round.state

  @spec insert_round_event(%Round{}, %Event{}, map) :: {:ok, %Round{}} | {:error, any}

  defp insert_round_event(round, event, round_changes) do
    Repo.transaction(fn ->
      {:ok, event} =
        event
        |> Event.changeset()
        |> Repo.insert()

      {:ok, round} =
        round
        |> Round.changeset(round_changes)
        |> Repo.update()

      %Round{round | events: [event | round.events]}
    end)
  end

  @spec create_game(id, list(%User{}), %Opts{}) :: {:ok, %Game{}} | {:error, any}

  def create_game(id, [host | _] = users, opts \\ %Opts{}) do
    players =
      users
      |> Enum.with_index()
      |> Enum.map(fn {user, index} -> %Player{user_id: user.id, turn: index} end)

    %Game{
      id: id,
      host_id: host.id,
      opts: opts,
      players: players,
      rounds: []
    }
    |> Game.changeset()
    |> Repo.insert()
  end

  @spec create_round(%Game{}) :: {:ok, %Round{}} | {:error, any}

  def create_round(%Game{id: game_id, players: players}) do
    num_players = length(players)
    deck = new_deck(@num_decks) |> Enum.shuffle()

    # deal hands
    num_hand_cards = @hand_size * num_players
    {:ok, hand_cards, deck} = deal_from_deck(deck, num_hand_cards)

    hands =
      hand_cards
      |> Enum.map(&%{"name" => &1, "face_up?" => false})
      |> Enum.chunk_every(@hand_size)

    # deal table card
    {:ok, table_card, deck} = deal_from_deck(deck)

    %Round{
      game_id: game_id,
      state: :flip_2,
      turn: 0,
      deck: deck,
      hands: hands,
      table_cards: [table_card],
      events: [],
      num_players: num_players
    }
    |> Round.changeset()
    |> Repo.insert()
  end

  @spec start_round(%Game{}) :: {:ok, %Game{}} | {:error, any}

  def start_round(game) when length(game.rounds) >= game.opts.num_rounds do
    {:error, :max_rounds}
  end

  def start_round(game) do
    with {:ok, round} <- create_round(game) do
      {:ok, %Game{game | rounds: [round | game.rounds]}}
    end
  end

  @spec current_round(%Game{}) :: %Round{} | nil

  def current_round(%Game{rounds: [round | _]}), do: round
  def current_round(_), do: nil

  @spec can_act?(%Game{} | %Round{}, %Player{}) :: boolean()

  def can_act?(%Game{rounds: []}), do: false

  def can_act?(%Game{rounds: [round | _]}, player) do
    can_act?(round, player)
  end

  def can_act?(%Round{state: :over}, _), do: false

  def can_act?(%Round{state: :flip_2} = round, player) do
    hand = Enum.at(round.hands, player.turn)
    num_cards_face_up(hand) < 2
  end

  def can_act?(%Round{} = round, player) do
    rem(round.turn, round.num_players) == player.turn
  end

  @spec handle_event(%Game{}, %Event{}) :: {:ok, %Game{}} | {:error, any}

  def handle_event(%Game{rounds: []}, _) do
    {:error, :no_round}
  end

  def handle_event(%Game{rounds: [%Round{state: :over} | _]}, _) do
    {:error, :round_over}
  end

  def handle_event(%Game{rounds: [round | _]} = game, event) do
    with {:ok, round} <- handle_round_event(round, event) do
      {:ok, %Game{game | rounds: List.replace_at(game.rounds, 0, round)}}
    end
  end

  @spec handle_round_event(%Round{}, %Event{}) :: {:ok, %Round{}} | {:error, any}

  def handle_round_event(%Round{state: :flip_2} = round, %Event{action: :flip} = event) do
    hands =
      List.update_at(
        round.hands,
        event.player.turn,
        &flip_card_at_index(&1, event.hand_index)
      )

    state = if Enum.all?(hands, &two_face_up?/1), do: :take, else: :flip_2
    insert_round_event(round, event, %{state: state, hands: hands})
  end

  def handle_round_event(%Round{state: :flip} = round, %Event{action: :flip} = event) do
    hands =
      List.update_at(round.hands, event.player.turn, &flip_card_at_index(&1, event.hand_index))

    {state, turn} =
      cond do
        Enum.all?(hands, &all_face_up?/1) ->
          {:over, round.turn}

        all_face_up?(Enum.at(hands, event.player.turn)) ->
          {:last_take, round.turn + 1}

        true ->
          {:take, round.turn + 1}
      end

    insert_round_event(round, event, %{state: state, turn: turn, hands: hands})
  end

  def handle_round_event(%Round{state: :take} = round, %Event{action: :take_from_deck} = event) do
    {:ok, card, deck} = deal_from_deck(round.deck)

    insert_round_event(round, event, %{
      state: :hold,
      deck: deck,
      held_card: %{"player_id" => event.player.id, "name" => card}
    })
  end

  def handle_round_event(%Round{state: :take} = round, %Event{action: :take_from_table} = event) do
    [card | table_cards] = round.table_cards

    insert_round_event(round, event, %{
      state: :hold,
      table_cards: table_cards,
      held_card: %{"player_id" => event.player.id, "name" => card}
    })
  end

  def handle_round_event(
        %Round{state: :last_take} = round,
        %Event{action: :take_from_deck} = event
      ) do
    {:ok, card, deck} = deal_from_deck(round.deck)

    insert_round_event(round, event, %{
      state: :last_hold,
      deck: deck,
      held_card: %{"player_id" => event.player.id, "name" => card}
    })
  end

  def handle_round_event(
        %Round{state: :last_take} = round,
        %Event{action: :take_from_table} = event
      ) do
    [card | table_cards] = round.table_cards

    insert_round_event(round, event, %{
      state: :last_hold,
      table_cards: table_cards,
      held_card: %{"player_id" => event.player.id, "name" => card}
    })
  end

  def handle_round_event(%Round{state: :hold} = round, %Event{action: :discard} = event) do
    hand = Enum.at(round.hands, event.player.turn)

    {state, turn} =
      if one_face_down?(hand) do
        {:take, round.turn + 1}
      else
        {:flip, round.turn}
      end

    insert_round_event(round, event, %{
      state: state,
      turn: turn,
      held_card: nil,
      table_cards: [round.held_card["name"] | round.table_cards]
    })
  end

  def handle_round_event(%Round{state: :hold} = round, %Event{action: :swap} = event) do
    {card, hand} =
      round.hands
      |> Enum.at(event.player.turn)
      |> swap_card(event.hand_index, round.held_card["name"])

    hands = List.replace_at(round.hands, event.player.turn, hand)

    {state, turn} =
      cond do
        Enum.all?(hands, &all_face_up?/1) ->
          {:over, round.turn}

        all_face_up?(hand) ->
          {:last_take, round.turn + 1}

        true ->
          {:take, round.turn + 1}
      end

    insert_round_event(round, event, %{
      state: state,
      turn: turn,
      held_card: nil,
      hands: hands,
      table_cards: [card | round.table_cards]
    })
  end

  def handle_round_event(%Round{state: :last_hold} = round, %Event{action: :discard} = event) do
    hands = List.update_at(round.hands, event.player.turn, &flip_all/1)

    {state, turn} =
      if Enum.all?(hands, &all_face_up?/1) do
        {:over, round.turn}
      else
        {:last_take, round.turn + 1}
      end

    insert_round_event(round, event, %{
      state: state,
      turn: turn,
      hands: hands,
      held_card: nil,
      table_cards: [round.held_card["name"] | round.table_cards]
    })
  end

  @spec playable_cards(%Round{}, %Player{}) :: list(binary())

  def playable_cards(%Round{state: :flip_2} = round, %Player{} = player) do
    hand = Enum.at(round.hands, player.turn)

    if num_cards_face_up(hand) < 2 do
      face_down_cards(hand)
    else
      []
    end
  end

  def playable_cards(round, player) do
    if can_act?(round, player) do
      case round.state do
        :take ->
          [:deck, :table]

        :flip ->
          hand = Enum.at(round.hands, player.turn)
          face_down_cards(hand)

        :last_take ->
          hand = Enum.at(round.hands, player.turn)
          [:deck, :table] ++ face_down_cards(hand)

        s when s in [:hold, :last_hold] ->
          [:held, :hand_0, :hand_1, :hand_2, :hand_3, :hand_4, :hand_5]
      end
    else
      []
    end
  end

  defp flip_card(card) do
    %{card | "face_up?" => true}
  end

  defp flip_card_at_index(hand, index) do
    List.update_at(hand, index, &flip_card/1)
  end

  defp flip_all(hand) do
    Enum.map(hand, &flip_card/1)
  end

  defp swap_card(hand, index, new_card) do
    old_card = Enum.at(hand, index)["name"]
    hand = List.replace_at(hand, index, %{"name" => new_card, "face_up?" => true})
    {old_card, hand}
  end

  defp num_cards_face_up(hand) do
    Enum.count(hand, & &1["face_up?"])
  end

  defp all_face_up?(hand) do
    num_cards_face_up(hand) == @hand_size
  end

  defp one_face_down?(hand) do
    num_cards_face_up(hand) == @hand_size - 1
  end

  defp two_face_up?(hand) do
    num_cards_face_up(hand) >= 2
  end

  defp face_down_cards(hand) do
    hand
    |> Enum.with_index()
    |> Enum.reject(fn {card, _} -> card["face_up?"] end)
    |> Enum.map(fn {_, index} -> String.to_existing_atom("hand_#{index}") end)
  end

  @spec new_deck(integer) :: list(card_name())
  defp new_deck(1), do: @card_names

  defp new_deck(n) when n > 1 do
    @card_names ++ new_deck(n - 1)
  end

  @spec deal_from_deck(list(card_name), integer) ::
          {:ok, list(card_name()), list(card_name())} | {:error, any}
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

  @spec deal_from_deck(list(card_name)) :: {:ok, card_name, list(card_name)} | {:error, any}
  defp deal_from_deck(deck) do
    with {:ok, [card], deck} <- deal_from_deck(deck, 1) do
      {:ok, card, deck}
    end
  end
end

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

# @spec game_exists?(id) :: boolean()
# def game_exists?(id) do
#   from(g in Game, where: [id: ^id])
#   |> Repo.exists?()
# end
