defmodule Golf.GamesTest do
  use Golf.DataCase

  alias Golf.Users.User
  alias Golf.{Users, Games}
  alias Golf.Games.{Opts, Event}

  test "two player game" do
    {:ok, user_1} =
      %User{name: "alice"}
      |> Users.insert_user()

    {:ok, user_2} =
      %User{name: "bob"}
      |> Users.insert_user()

    id = Games.gen_id()
    users = [user_1, user_2]
    opts = %Opts{num_rounds: 2}

    {:ok, game} =
      Games.create_game(id, users, opts)

    assert Games.state(game) == :no_rounds

    p1 = Enum.at(game.players, 0)
    p2 = Enum.at(game.players, 1)

    {:ok, game} = Games.start_round(game)

    assert Games.state(game) == :flip_2

    event = Event.new(game, p1, :flip, 0)
    {:ok, game} = Games.handle_event(game, event)

    assert Games.state(game) == :flip_2

    {:ok, found_game} = Games.fetch_game(game.id)
    assert game == found_game

    event = Event.new(game, p2, :flip, 5)
    {:ok, game} = Games.handle_event(game, event)

    assert Games.state(game) == :flip_2
    assert Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    {:ok, found_game} = Games.fetch_game(game.id)
    assert game == found_game

    event = Event.new(game, p2, :flip, 4)
    {:ok, game} = Games.handle_event(game, event)

    assert Games.state(game) == :flip_2
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :flip, 1)
    {:ok, game} = Games.handle_event(game, event)

    assert Games.state(game) == :take
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :take_from_deck)
    {:ok, game} = Games.handle_event(game, event)

    assert Games.state(game) == :hold
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    {:ok, found_game} = Games.fetch_game(id)
    assert game == found_game

    event = Event.new(game, p1, :discard)
    {:ok, game} = Games.handle_event(game, event)

    assert Games.state(game) == :flip
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    {:ok, found_game} = Games.fetch_game(id)
    assert game == found_game

    event = Event.new(game, p1, :flip, 2)
    {:ok, game} = Games.handle_event(game, event)

    assert Games.state(game) == :take
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :take_from_table)
    {:ok, game} = Games.handle_event(game, event)

    assert Games.state(game) == :hold
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :swap, 3)
    {:ok, game} = Games.handle_event(game, event)

    dbg(Games.current_round(game))
  end
end
