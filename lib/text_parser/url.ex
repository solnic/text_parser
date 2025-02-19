defmodule TextParser.Tokens.URL do
  defstruct [:value, :position]

  @type t :: %__MODULE__{
          value: String.t(),
          position: {non_neg_integer(), non_neg_integer()}
        }

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
