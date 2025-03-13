defmodule TextParser.Tokens.URL do
  use TextParser.Token,
    pattern: ~r/(?:^|\s)((?!@)(?:https?:\/\/)?[^\s]+\.[a-zA-Z]{2,}(?:\/[^\s]*)?)/ui,
    trim_chars: [".", ",", ";", "!", "?", ")"]

  @impl true
  def is_valid?(url_text) when is_binary(url_text) do
    url_text = ensure_scheme(url_text)

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
    case URI.new(url) do
      {:ok, %URI{host: host}} when not is_nil(host) -> {:ok, host}
      _ -> :error
    end
  end

  defp ensure_scheme(uri) do
    if String.starts_with?(uri, ["http://", "https://"]) do
      uri
    else
      "https://#{uri}"
    end
  end
end
