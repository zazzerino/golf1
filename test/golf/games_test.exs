defmodule Golf.GamesTest do
  require Golf.Games
  use Golf.DataCase
  alias Golf.{Users, Games}
  alias Golf.Users.User
  alias Golf.Games.{Opts, Event}

  test "2p game" do
    {:ok, user_1} =
      %User{name: "alice"}
      |> Users.insert_user()

    {:ok, user_2} =
      %User{name: "bob"}
      |> Users.insert_user()

    game_id = Ecto.UUID.generate()
    opts = %Opts{num_rounds: 2}

    {:ok, game} = Games.create_game(game_id, [user_1, user_2], opts)

    p1 = Enum.find(game.players, &(&1.user_id == user_1.id))
    p2 = Enum.find(game.players, &(&1.user_id == user_2.id))

    refute Games.players_turn?(game, p1.turn)
    refute Games.players_turn?(game, p2.turn)

    {:ok, game} = Games.start_next_round(game)

    assert Games.players_turn?(game, p1.turn)
    assert Games.players_turn?(game, p2.turn)

    round_id = Games.current_round(game).id

    event = Event.new(round_id, p1.id, :flip, 0)
    {:ok, game} = Games.handle_event(game, event)

    found_game = Games.get_game(game.id)
    assert game == found_game

    event = Event.new(round_id, p2.id, :flip, 5)
    {:ok, game} = Games.handle_event(game, event)

    assert Games.players_turn?(game, p1.turn)
    assert Games.players_turn?(game, p2.turn)

    event = Event.new(round_id, p2.id, :flip, 4)
    {:ok, game} = Games.handle_event(game, event)

    assert Games.players_turn?(game, p1.turn)
    refute Games.players_turn?(game, p2.turn)

    event = Event.new(round_id, p1.id, :flip, 1)
    {:ok, game} = Games.handle_event(game, event)

    assert Games.players_turn?(game, p1.turn)
    refute Games.players_turn?(game, p2.turn)

    dbg(game)
  end
end
