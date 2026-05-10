defmodule AgendaCli.Store do
  @moduledoc """
  Leitura e escrita de `contacts.json` no diretório de execução.
  """

  @filename "contacts.json"

  @doc """
  Carrega a lista de contatos do arquivo ou retorna lista vazia.
  """
  def load do
    path = contacts_path()

    case File.read(path) do
      {:ok, ""} ->
        []

      {:ok, content} ->
        content
        |> Jason.decode!()
        |> Enum.map(&normalize_contact/1)

      {:error, :enoent} ->
        []

      {:error, reason} ->
        raise "Não foi possível ler #{path}: #{inspect(reason)}"
    end
  end

  @doc """
  Persiste a lista completa de contatos no arquivo.
  """
  def save(contacts) when is_list(contacts) do
    path = contacts_path()
    data = Jason.encode!(contacts, pretty: true)
    File.write!(path, data)
  end

  defp contacts_path do
    File.cwd!()
    |> Path.join(@filename)
  end

  defp normalize_contact(%{
         "id" => id,
         "name" => name,
         "company" => company,
         "phone" => phone,
         "email" => email
       }) do
    %{id: id, name: name, company: company, phone: phone, email: email}
  end
end
