defmodule Golf.Links do
  import Ecto.Query

  alias Golf.Repo
  alias Golf.Links.Link
  alias Golf.Games.Game
  alias Golf.Lobbies.Lobby

  @doc """
  Generates a random 6 character id.
  Credit: https://gist.github.com/danschultzer/99c21ba403fd7f49a26cc40571ff5cce
  """
  def gen_id() do
    min = String.to_integer("100000", 36)
    max = String.to_integer("ZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
  end

  def get_lobby_id(link_id) do
    from(link in Link,
      where: [id: ^link_id],
      join: lobby in Lobby,
      on: lobby.id == link.lobby_id,
      select: lobby.id
    )
    |> Repo.one()
  end

  def get_lobby(link_id) do
    if lobby_id = get_lobby_id(link_id) do
      Golf.Lobbies.get_lobby(lobby_id)
    end
  end

  def get_game_id(link_id) do
    from(l in Link,
      where: [id: ^link_id],
      join: g in Game,
      on: g.id == l.game_id,
      select: g.id
    )
    |> Repo.one()
  end

  def get_game(link_id) do
    if game_id = get_game_id(link_id) do
      Golf.Games.get_game(game_id)
    end
  end

  def new_link(lobby_id) do
    %Link{
      id: gen_id(),
      lobby_id: lobby_id
    }
  end

  def create_link_lobby(user) do
    Repo.transaction(fn ->
      {:ok, lobby} = Golf.Lobbies.create_lobby(user)

      {:ok, link} =
        new_link(lobby.id)
        |> Link.changeset()
        |> Repo.insert()

      {link.id, lobby}
    end)
  end

  def create_link_game(link_id, users, opts) when is_binary(link_id) do
    Repo.transaction(fn ->
      {:ok, game} = Golf.Games.create_game(users, opts)

      # update 1, return nothing
      {1, nil} =
        from(l in Link, where: [id: ^link_id])
        |> Repo.update_all([set: [game_id: game.id]])

      game
    end)
  end
end
