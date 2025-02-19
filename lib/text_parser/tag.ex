defmodule TextParser.Tokens.Tag do
  defstruct [:value, :position]

  @type t :: %__MODULE__{
          value: String.t(),
          position: {non_neg_integer(), non_neg_integer()}
        }

  @doc """
  Validates if the given text is a valid tag.
  """
  def is_valid?(tag_text) when is_binary(tag_text) do
    case tag_text do
      "#" <> rest ->
        rest != "" and
          String.match?(rest, ~r/^\S+$/) and
          String.match?(rest, ~r/[[:alpha:]]/)

      _ ->
        false
    end
  end

  def is_valid?(_), do: false
end
