defmodule Golf do
  @moduledoc """
  Golf keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  def rotate(list, n) do
    {left, right} = Enum.split(list, n)
    right ++ left
  end

  def maybe_rotate(list, n) when n in [0, nil], do: list
  def maybe_rotate(list, n), do: rotate(list, n)

  def subscribe(topic) when is_binary(topic) do
    Phoenix.PubSub.subscribe(Golf.PubSub, topic)
  end

  def broadcast(topic, msg) when is_binary(topic) do
    Phoenix.PubSub.broadcast(Golf.PubSub, topic, msg)
  end

  def broadcast_from(topic, msg) when is_binary(topic) do
    Phoenix.PubSub.broadcast_from(Golf.PubSub, self(), topic, msg)
  end
end
