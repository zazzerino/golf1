defmodule Golf.Users.User do
  use Golf.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "users" do
    field :name, :string
    timestamps()
  end

  def changeset(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
