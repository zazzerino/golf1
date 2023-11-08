defmodule Golf.Users do
  import Ecto.Query
  alias Ecto.Multi
  alias Golf.Repo
  alias Golf.Users.{User, Token}

  @default_username "user"

  def get_user(user_id) do
    Repo.get(User, user_id)
  end

  def get_user_by_token(token) do
    from(t in Token,
      where: [token: ^token],
      join: u in assoc(t, :user),
      select: u
    )
    |> Repo.one()
  end

  def insert_user(%User{} = user) do
    Repo.insert(user)
  end

  def insert_token(token) do
    Repo.insert(token)
  end

  def create_user(name \\ @default_username) do
    Multi.new()
    |> Multi.insert(:user, User.changeset(%User{name: name}))
    |> Multi.insert(:token, fn %{user: user} ->
      Token.new(user)
    end)
    |> Repo.transaction()
  end
end
