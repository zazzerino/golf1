defmodule Golf.Repo.Migrations.CreateLobbiesTable do
  use Ecto.Migration

  def change do
    create table("lobbies", primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :host_id, references("users")
      add :user_ids, {:array, :integer}
      timestamps()
    end
  end
end
