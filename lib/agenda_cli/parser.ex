defmodule AgendaCli.Parser do
  @moduledoc """
  Parsing de flags e do comando `search` com cláusulas e pattern matching.
  """

  @doc """
  Tokeniza a linha em palavras (separadas por espaço).
  """
  def tokenize(line) when is_binary(line) do
    line
    |> String.trim()
    |> String.split(~r/\s+/, trim: true)
  end

  @doc """
  Interpreta o texto após o comando `search`.
  Retorna `{:name, valor}`, `{:phone, valor}`, `{:email, valor}` ou `:error`.
  """
  def parse_search([]), do: :error
  def parse_search(["--name" | rest]), do: single_search_flag(:name, rest)
  def parse_search(["--phone" | rest]), do: single_search_flag(:phone, rest)
  def parse_search(["--email" | rest]), do: single_search_flag(:email, rest)
  def parse_search(_), do: :error

  defp single_search_flag(field, rest) do
    {value, leftover} = take_value(rest, [])

    cond do
      value == "" -> :error
      leftover != [] -> :error
      true -> {field, value}
    end
  end

  @doc """
  Extrai flags `--name`, `--company`, `--phone`, `--email` até esgotar os tokens.
  Retorna `{mapa_de_attrs, tokens_restantes}`.
  """
  def parse_flags([]), do: {%{}, []}
  def parse_flags(["--name" | rest]), do: take_flag(:name, rest)
  def parse_flags(["--company" | rest]), do: take_flag(:company, rest)
  def parse_flags(["--phone" | rest]), do: take_flag(:phone, rest)
  def parse_flags(["--email" | rest]), do: take_flag(:email, rest)
  def parse_flags(other), do: {%{}, other}

  defp take_flag(key, rest) do
    {value, tail} = take_value(rest, [])
    {acc, tail2} = parse_flags(tail)
    {Map.put(acc, key, value), tail2}
  end

  defp take_value([], acc), do: {join_rev(acc), []}

  defp take_value([t | rest] = all, acc) when is_binary(t) do
    if String.starts_with?(t, "--") do
      {join_rev(acc), all}
    else
      take_value(rest, [t | acc])
    end
  end

  defp join_rev(acc) do
    acc
    |> Enum.reverse()
    |> Enum.join(" ")
  end
end
