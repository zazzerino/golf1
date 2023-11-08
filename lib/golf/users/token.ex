defmodule Golf.Users.Token do
  use Golf.Schema
  alias Golf.Users.User
  alias __MODULE__

  @salt "ZGyQachRbPWdgzkTuLKSoMMUTcCnWSqnxqgaPAdq4nJM8IZ3JthI6GtIMZLzEjri"

  schema "users_tokens" do
    belongs_to :user, Golf.Users.User
    field :token, :binary
    timestamps(updated_at: false)
  end

  def new(%User{} = user) do
    data = Map.take(user, [:id, :name])
    token = Phoenix.Token.sign(GolfWeb.Endpoint, @salt, data)
    %Token{user_id: user.id, token: token}
  end
end
