defmodule TextParser.Tokens.Tag do
  use TextParser.Token,
    parser: :tag_parser,
    trim_chars: [".", ",", "!", "?"]

  import NimbleParsec

  hashtag =
    ignore(ascii_string([?\s], min: 0))
    |> string("#")
    |> concat(
      ascii_char([?a..?z, ?A..?Z])
      |> concat(ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-], min: 0))
    )
    |> reduce({List, :to_string, []})
    |> map({String, :replace, [~r/[^\w\-#]+$/u, ""]})

  defparsec(:tag_parser, hashtag)

  @impl true
  def is_valid?(tag_text) when is_binary(tag_text) do
    case tag_text do
      "#" <> rest ->
        rest != "" and
          String.match?(rest, ~r/^\S+$/) and
          String.match?(rest, ~r/^[[:alpha:]]/)

      _ ->
        false
    end
  end

  def is_valid?(_), do: false
end
