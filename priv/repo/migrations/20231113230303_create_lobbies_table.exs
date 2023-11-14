defmodule Golf.Repo.Migrations.CreateLobbiesTable do
  use Ecto.Migration

  def change do
    create table("lobbies", primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :host_id, references("users")
      timestamps()
    end

    create table("users_lobbies", primary_key: false) do
      add :user_id, references("users")
      add :lobby_id, references("lobbies", type: :uuid)
      timestamps()
    end

    create unique_index("users_lobbies", [:user_id, :lobby_id])
  end
end
