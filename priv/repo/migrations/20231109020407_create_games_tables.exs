defmodule Golf.Repo.Migrations.CreateGamesTables do
  use Ecto.Migration

  def change do
    create table("games", primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :host_id, references("users")
      timestamps()
    end

    create table("opts") do
      add :game_id, references("games", type: :uuid)
      add :num_rounds, :integer
      timestamps()
    end

    create unique_index("opts", [:game_id])

    create table("players") do
      add :game_id, references("games", type: :uuid)
      add :user_id, references("users")
      add :turn, :integer
      timestamps()
    end

    create unique_index("players", [:game_id, :user_id])
    create unique_index("players", [:game_id, :turn])

    create table("rounds") do
      add :game_id, references("games", type: :uuid)
      add :state, :string
      add :turn, :integer
      add :deck, {:array, :string}
      add :table_cards, {:array, :string}
      add :hands, {:array, {:array, :map}}
      add :held_card, :map
      add :flipped?, :boolean
      timestamps()
    end

    create table("events") do
      add :round_id, references("rounds")
      add :player_id, references("players")
      add :action, :string
      add :hand_index, :integer
      timestamps(updated_at: false)
    end
  end
end
