defmodule TextParser.Behaviour do
  @moduledoc """
  Behaviour for implementing custom text parsers.

  ## Example

      defmodule MyParser do
        use TextParser

        def validate(%TextParser.Tokens.Tag{value: value} = tag) do
          if String.length(value) >= 66, do: {:error, "tag too long"}, else: {:ok, tag}
        end
      end
  """

  @doc """
  Callback for validating a token.

  This should be implemented by each parser module to define its specific
  validation rules. The callback receives a token struct and should return
  either `{:ok, token}` or `{:error, reason}`.
  """
  @callback validate(token :: struct()) :: {:ok, struct()} | {:error, String.t()}
end
