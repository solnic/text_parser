defmodule TextParser.Token do
  @moduledoc """
  Behaviour for implementing custom token extractors.

  ## Example

      defmodule MyApp.CustomToken do
        use TextParser.Token,
          pattern: ~r/(?:^|\s)(@\S*)/u,
          trim_chars: [",", ".", "!", "?"]

        def is_valid?(token) do
          # implement validation logic
        end
      end
  """

  @doc """
  When used, defines the token struct and implements the behaviour.

  ## Options

    * `:pattern` - Required. A regex pattern to match tokens in text
    * `:trim_chars` - Optional. A list of characters to trim from the end of matched tokens
  """
  defmacro __using__(opts) do
    quote location: :keep do
      @behaviour TextParser.Token

      defstruct [:value, :position]

      @type t :: %__MODULE__{
              value: String.t(),
              position: {non_neg_integer(), non_neg_integer()}
            }

      @pattern unquote(opts[:pattern])
      @trim_chars unquote(Keyword.get(opts, :trim_chars, []))

      @impl true
      def extract(text) when is_binary(text) do
        Regex.scan(@pattern, text, return: :index)
        |> Enum.reduce([], fn [{match_start, _match_length}, {token_start, token_length}],
                              acc ->
          absolute_start = match_start + (token_start - match_start)
          token_text = binary_part(text, absolute_start, token_length)

          clean_token = clean_token(token_text)

          if is_valid?(clean_token) do
            token = %__MODULE__{
              value: clean_token,
              position: {absolute_start, absolute_start + byte_size(clean_token)}
            }

            [token | acc]
          else
            acc
          end
        end)
        |> Enum.reverse()
      end

      defp clean_token(token) do
        token = String.trim(token)

        # First remove any non-word characters from the end (including emoji)
        token = String.replace(token, ~r/[^\w\-]+$/u, "")

        # Then remove any specific trailing characters
        Enum.reduce(@trim_chars, token, fn char, acc ->
          String.trim_trailing(acc, char)
        end)
      end

      defoverridable extract: 1
    end
  end

  @doc """
  Callback for extracting tokens from text.

  The implementation should return a list of token structs, where each token
  has a `:value` and `:position` field. The position should be a tuple of
  `{start_pos, end_pos}` indicating the token's position in the text.
  """
  @callback extract(text :: String.t()) :: [struct()]

  @doc """
  Callback for validating a token value.

  This should be implemented by each token module to define its specific
  validation rules.
  """
  @callback is_valid?(token :: term()) :: boolean()
end
