defmodule Golf.UserLobby do
  use Golf.Schema

  @primary_key false

  schema "users_lobbies" do
    belongs_to :user, Golf.Users.User
    belongs_to :lobby, Golf.Games.Lobby, type: Ecto.UUID
    timestamps()
  end
end
