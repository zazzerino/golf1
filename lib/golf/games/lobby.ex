defmodule Golf.Games.Lobby do
  import Ecto.Changeset
  use Golf.Schema

  @primary_key {:id, Ecto.UUID, []}

  schema "lobbies" do
    belongs_to :host, Golf.Users.User
    field :user_ids, {:array, :integer}
    timestamps()
  end

  def changeset(lobby, attrs \\ %{}) do
    lobby
    |> cast(attrs, [:id, :host_id, :user_ids])
    |> validate_required([:id, :host_id, :user_ids])
  end
end
