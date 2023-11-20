defmodule Golf.Links.Link do
  use Golf.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}

  schema "game_links" do
    belongs_to :lobby, Golf.Lobbies.Lobby
    belongs_to :game, Golf.Games.Game
    has_many :messages, Golf.Chat.Message
    timestamps()
  end

  def changeset(link, attrs \\ %{}) do
    link
    |> cast(attrs, [:id, :lobby_id, :game_id])
    |> validate_required([:id, :lobby_id])
  end

  def game_changeset(link, attrs) do
    link
    |> changeset(attrs)
    |> validate_required([:game_id])
  end
end
