defmodule Golf.Repo.Migrations.CreateLobbiesTable do
  use Ecto.Migration

  def change do
    create table("lobbies") do
      add :host_id, references("users")
      timestamps()
    end

    create table("lobbies_users", primary_key: false) do
      add :lobby_id, references("lobbies")
      add :user_id, references("users")
      timestamps()
    end

    create unique_index("lobbies_users", [:lobby_id, :user_id])
  end
end
