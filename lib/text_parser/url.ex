defmodule TextParser.Tokens.URL do
  use TextParser.Token

  @url_regex ~r/(?:^|\s)(?<!@)((?:https?:\/\/)?[^\s]+\.[a-zA-Z]{2,}(?:\/[^\s]*)?)/ui

  @doc """
  Extracts URLs from the given text.
  """
  @impl true
  def extract(text) when is_binary(text) do
    Regex.scan(@url_regex, text, return: :index)
    |> Enum.reduce([], fn [{match_start, _match_length}, {url_start, url_length}], acc ->
      absolute_start = match_start + (url_start - match_start)
      uri = binary_part(text, absolute_start, url_length)

      if String.starts_with?(uri, "@") do
        acc
      else
        cleaned_uri =
          uri
          |> String.trim_trailing(".")
          |> String.trim_trailing(",")
          |> String.trim_trailing(";")
          |> String.trim_trailing("!")
          |> String.trim_trailing("?")
          |> String.trim_trailing(")")

        if is_valid?(cleaned_uri) do
          url = %__MODULE__{
            value: cleaned_uri,
            position: {absolute_start, absolute_start + byte_size(cleaned_uri)}
          }

          [url | acc]
        else
          acc
        end
      end
    end)
    |> Enum.reverse()
  end

  @doc """
  Validates if the given text is a valid URL.
  """
  def is_valid?(url_text) when is_binary(url_text) do
    case extract_domain(url_text) do
      {:ok, domain} ->
        case Domainatrex.parse(domain) do
          {:ok, %{domain: domain, tld: tld}} when domain != "" and tld != "" -> true
          _ -> false
        end

      _ ->
        false
    end
  end

  def is_valid?(_), do: false

  defp extract_domain(url) do
    case URI.new(ensure_http_prefix(url)) do
      {:ok, %URI{host: host}} when not is_nil(host) -> {:ok, host}
      _ -> :error
    end
  end

  defp ensure_http_prefix(uri) do
    if String.starts_with?(uri, ["http://", "https://"]) do
      uri
    else
      "https://#{uri}"
    end
  end
end
