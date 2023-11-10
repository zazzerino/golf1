defmodule Golf.Repo.Migrations.CreateGamesTables do
  use Ecto.Migration

  def change do
    create table("games") do
      add :host_id, references("users")
      add :num_rounds, :integer
      timestamps()
    end

    create table("players") do
      add :user_id, references("users")
      add :game_id, references("games")
      add :turn, :integer
      timestamps()
    end

    create table("rounds") do
      add :game_id, references("games")
      add :state, :string
      add :turn, :integer
      add :deck, {:array, :string}
      add :table_cards, {:array, :string}
      add :hands, {:array, {:array, :map}}
      add :held_card, :map
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
