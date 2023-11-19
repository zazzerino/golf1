defmodule Golf.Repo.Migrations.CreateGameLinksTable do
  use Ecto.Migration

  def change do
    create table("game_links", primary_key: false) do
      add :id, :string, primary_key: true
      add :lobby_id, references("lobbies")
      add :game_id, references("games")
      timestamps()
    end
  end
end
