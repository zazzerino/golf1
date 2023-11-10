defmodule Golf.GamesTest do
  use ExUnit.Case
  alias Golf.Games
  # alias Golf.Games.{Game, Opts, Player}

  test "game" do
    game = Games.create_game(1, 2)
    game = Games.add_player(game, 2)
    game = Games.start_next_round(game)
    # |> dbg()
  end
end
