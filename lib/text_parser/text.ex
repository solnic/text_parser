defmodule TextParser.Text do
  @type t :: %__MODULE__{
          value: String.t(),
          tokens: [struct()]
        }

  defstruct value: "", tokens: []

  @doc """
  Creates a new Text struct from the given text value.
  """
  def new(value) when is_binary(value) do
    %__MODULE__{value: value}
  end
end
