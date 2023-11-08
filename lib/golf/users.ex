defmodule Golf.Users do
  alias Golf.Repo
  alias Golf.Users.User

  @default_username "user"

  def get_user(user_id) do
    Repo.get(User, user_id)
  end

  def insert_user(user \\ %User{name: @default_username}) do
    Repo.insert(User.changeset(user))
  end
end
