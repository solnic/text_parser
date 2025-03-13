defmodule TextParser.Token do
  @moduledoc """
  Behaviour for implementing custom token extractors.

  ## Example

      defmodule MyApp.CustomToken do
        use TextParser.Token

        def extract(text) do
          # implement token extraction logic
        end
      end
  """

  @doc """
  When used, defines the token struct and implements the behaviour.
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour TextParser.Token

      defstruct [:value, :position]

      @type t :: %__MODULE__{
              value: String.t(),
              position: {non_neg_integer(), non_neg_integer()}
            }
    end
  end

  @doc """
  Callback for extracting tokens from text.

  The implementation should return a list of token structs, where each token
  has a `:value` and `:position` field. The position should be a tuple of
  `{start_pos, end_pos}` indicating the token's position in the text.
  """
  @callback extract(text :: String.t()) :: [struct()]
end
