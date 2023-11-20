defmodule Golf.Chat do
  import Ecto.Query

  alias Golf.Repo
  alias Golf.Users.User
  alias Golf.Chat.Message

  def insert_message(message) do
    message
    |> Message.changeset()
    |> Repo.insert()
  end

  def get_messages(link_id) do
    from(m in Message,
      where: [link_id: ^link_id],
      order_by: [desc: m.inserted_at],
      join: u in User,
      on: u.id == m.user_id,
      select: %{m | username: u.name}
    )
    |> Repo.all()
  end
end
