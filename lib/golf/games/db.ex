defmodule Golf.Games.Db do
  import Ecto.Query
  alias Golf.Repo
  alias Golf.Games.{Game, Player, Round, Event}

  def get_game(game_id) do
    events_query = from(e in Event, order_by: [desc: :inserted_at])
    players_query = from(p in Player, order_by: p.turn)

    Repo.get(Game, game_id)
    |> Repo.preload(rounds: [events: events_query], players: players_query)
  end

  def upsert_game(game) do
    Repo.transaction(fn ->
      {:ok, game} = Repo.insert_or_update(Game.changeset(game))

      players =
        Enum.map(game.players, fn p ->
          {:ok, player} = Repo.insert_or_update(Player.changeset(p))
          player
        end)

      rounds =
        Enum.map(game.rounds, fn r ->
          {:ok, round} = Repo.insert_or_update(Round.changeset(r))

          events =
            Enum.map(round.events, fn e ->
              {:ok, event} = Repo.insert_or_update(Event.changeset(e))
              event
            end)

          %Round{round | events: events}
        end)

      %Game{game | players: players, rounds: rounds}
    end)
  end
end
