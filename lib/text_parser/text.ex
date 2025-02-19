defmodule TextParser.Text do
  alias TextParser.Tokens.{URL, Tag, Mention}

  defstruct value: "", urls: [], tags: [], mentions: []

  @type t :: %__MODULE__{
          value: String.t(),
          urls: [URL.t()],
          tags: [Tag.t()],
          mentions: [Mention.t()]
        }

  @doc """
  Creates a new Text struct from the given text value.
  """
  def new(value) when is_binary(value) do
    %__MODULE__{value: value}
  end
end
