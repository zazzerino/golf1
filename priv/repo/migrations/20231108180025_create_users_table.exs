defmodule Golf.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table("users") do
      add :name, :string
      timestamps()
    end

    create table("users_tokens") do
      add :user_id, references("users", on_delete: :delete_all)
      add :token, :binary
      timestamps(updated_at: false)
    end
  end
end
