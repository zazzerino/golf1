defmodule Golf.Users.User do
  use Golf.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    timestamps()
  end

  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
