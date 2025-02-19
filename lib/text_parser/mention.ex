defmodule TextParser.Tokens.Mention do
  defstruct [:value, :position]

  @type t :: %__MODULE__{
          value: String.t(),
          position: {non_neg_integer(), non_neg_integer()}
        }

  @doc """
  Validates if the given text is a valid mention.
  """
  def is_valid?(mention_text) when is_binary(mention_text) do
    case mention_text do
      "@" <> rest ->
        rest != "" and String.match?(rest, ~r/^\S+$/)

      _ ->
        false
    end
  end

  def is_valid?(_), do: false
end
