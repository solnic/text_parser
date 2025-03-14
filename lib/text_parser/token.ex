defmodule TextParser.Token do
  @moduledoc """
  Behaviour for implementing custom token extractors.

  ## Example

      defmodule MyApp.CustomToken do
        use TextParser.Token,
          parser: :tag_parser,
          trim_chars: [",", ".", "!", "?"]

        import NimbleParsec

        hashtag =
          ignore(ascii_string([?\s], min: 0))
          |> ascii_char([?@])
          |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 1)
          |> reduce({Enum, :join, []})

        defparsec :tag_parser, hashtag

        def is_valid?(token) do
          # implement validation logic
        end
      end
  """

  @doc """
  When used, defines the token struct and implements the behaviour.

  ## Options

    * `:parser` - Required. The name of the NimbleParsec parser function
    * `:pattern` - Optional. A regex pattern to match tokens in text (legacy support)
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
      @parser unquote(opts[:parser])
      @trim_chars unquote(Keyword.get(opts, :trim_chars, []))

      @impl true
      def extract(text) when is_binary(text) do
        if @parser do
          extract_with_parsec(text)
        else
          extract_with_regex(text)
        end
      end

      defp extract_with_parsec(text) do
        extract_tokens(text, [], 0)
      end

      defp extract_tokens("", acc, _), do: Enum.reverse(acc)

      defp extract_tokens(text, acc, offset) do
        case apply(__MODULE__, @parser, [text]) do
          {:ok, [token], rest, %{}, {token_offset, _length}, _} ->
            clean_token = clean_token(token)

            {prefix, _} = String.split_at(text, token_offset)
            absolute_offset = offset + byte_size(prefix)
            token_byte_length = byte_size(clean_token)

            new_acc =
              if is_valid?(clean_token) do
                [
                  %__MODULE__{
                    value: clean_token,
                    position: {absolute_offset, absolute_offset + token_byte_length}
                  }
                  | acc
                ]
              else
                acc
              end

            {prefix, _} = String.split_at(text, String.length(text) - String.length(rest))
            new_offset = offset + byte_size(prefix)
            extract_tokens(rest, new_acc, new_offset)

          _ ->
            case String.split_at(text, 1) do
              {"", ""} -> Enum.reverse(acc)
              {char, rest} -> extract_tokens(rest, acc, offset + byte_size(char))
            end
        end
      end

      defp extract_with_regex(text) do
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

      defp clean_token(token) when is_binary(token) do
        token = String.trim(token)

        token = String.replace(token, ~r/[^\w\-]+$/u, "")

        Enum.reduce(@trim_chars, token, fn char, acc ->
          String.trim_trailing(acc, char)
        end)
      end

      defp clean_token(token), do: to_string(token)

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
