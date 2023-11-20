defmodule Golf.Users do
  import Ecto.Query

  alias Golf.Repo
  alias Golf.Users.User
  alias Golf.Links.Link
  alias Golf.Games.{Game, Player}

  @default_name "user"

  def get_user(user_id) do
    Repo.get(User, user_id)
  end

  def get_users([]), do: []

  def get_users(user_ids) do
    from(u in User, where: u.id in ^user_ids)
    |> Repo.all()
  end

  def insert_user(user \\ %User{name: @default_name}) do
    Repo.insert(User.changeset(user))
  end

  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def get_links(user_id) do
    from(u in User,
      where: [id: ^user_id],
      join: p in Player,
      on: [user_id: u.id],
      join: g in Game,
      on: [id: p.game_id],
      order_by: [desc: g.inserted_at],
      join: l in Link,
      on: g.id == l.game_id,
      select: l
    )
    |> Repo.all()
  end
end
