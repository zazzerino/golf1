defmodule Golf.Users do
  import Ecto.Query

  alias Golf.Repo
  alias Golf.Users.User

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
end
