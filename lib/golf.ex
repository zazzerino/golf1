defmodule Golf do
  @moduledoc """
  Golf keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  def gen_id(), do: Ecto.UUID.generate()

  def maybe_rotate(list, n) when n in [0, nil], do: list
  def maybe_rotate(list, n), do: rotate(list, n)

  def rotate(list, n) do
    {left, right} = Enum.split(list, n)
    right ++ left
  end

  # # https://gist.github.com/danschultzer/99c21ba403fd7f49a26cc40571ff5cce
  # def gen_id() do
  #   min = String.to_integer("100000", 36)
  #   max = String.to_integer("ZZZZZZ", 36)

  #   max
  #   |> Kernel.-(min)
  #   |> :rand.uniform()
  #   |> Kernel.+(min)
  #   |> Integer.to_string(36)
  # end
end
