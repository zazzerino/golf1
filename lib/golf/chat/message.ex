defmodule Golf.Chat.Message do
  use Golf.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:link_id, :user_id, :content, :username, :inserted_at]}
  schema "chat_messages" do
    belongs_to :link, Golf.Links.Link, type: :string
    belongs_to :user, Golf.Users.User
    field :content, :string
    timestamps()

    field :username, :string, virtual: true
  end

  def changeset(message, attrs \\ %{}) do
    message
    |> cast(attrs, [:link_id, :user_id, :content])
    |> validate_required([:link_id, :user_id, :content])
  end

  def new(link_id, user, content) do
    %__MODULE__{
      link_id: link_id,
      content: content,
      user_id: user.id,
      username: user.name
    }
  end
end
