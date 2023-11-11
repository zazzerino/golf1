defmodule Golf.GamesDbTest do
  use Golf.DataCase, async: true
  alias Golf.{Users, Games}
  alias Golf.Users.User
  alias Golf.Games.Event

  test "game" do
    {:ok, user1} =
      %User{name: "alice"}
      |> Users.insert_user()

    {:ok, user2} =
      %User{name: "bob"}
      |> Users.insert_user()

    {:ok, game} =
      Games.create_game(user1.id, _num_rounds = 2)
      |> Games.Db.upsert_game()

    found_game = Games.Db.get_game(game.id)
    assert game == found_game

    {:ok, game} =
      Games.add_player(game, user2.id)
      |> Games.Db.upsert_game()

    {:ok, game} =
      Games.start_next_round(game)
      |> Games.Db.upsert_game()

    found_game = Games.Db.get_game(game.id)
    assert game == found_game

    p1_id = Enum.find(game.players, &(&1.user_id == user1.id)).id
    p2_id = Enum.find(game.players, &(&1.user_id == user2.id)).id

    event = Event.new(hd(game.rounds).id, p1_id, :flip, 0)
    {:ok, game} = Games.handle_event(game, event)
    {:ok, game} = Games.Db.upsert_game(game)

    dbg(game)
  end
end
