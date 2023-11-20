defmodule Golf.Repo.Migrations.CreateChatMessagesTable do
  use Ecto.Migration

  def change do
    create table("chat_messages") do
      add :link_id, references("game_links", type: :string)
      add :user_id, references("users")
      add :content, :string
      timestamps()
    end
  end
end
