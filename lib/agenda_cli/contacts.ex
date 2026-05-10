defmodule AgendaCli.Contacts do
  @moduledoc """
  Funções puras para manipular a lista de contatos.
  """

  @doc """
  Gera um novo id (timestamp em milissegundos).
  """
  def new_id do
    :erlang.system_time(:millisecond)
  end

  @doc """
  Adiciona um contato com os campos obrigatórios.
  """
  def add(contacts, attrs) when is_list(contacts) and is_map(attrs) do
    contact = %{
      id: new_id(),
      name: attrs.name,
      company: attrs.company,
      phone: attrs.phone,
      email: attrs.email
    }

    [contact | contacts]
  end

  @doc """
  Remove o contato com o id informado.
  """
  def delete(contacts, id) when is_list(contacts) do
    Enum.reject(contacts, fn c -> c.id == id end)
  end

  @doc """
  Atualiza campos presentes em `attrs` (chaves :name, :company, :phone, :email).
  """
  def edit(contacts, id, attrs) when is_list(contacts) and is_map(attrs) do
    Enum.map(contacts, fn c ->
      if c.id == id do
        c
        |> maybe_put(:name, attrs[:name])
        |> maybe_put(:company, attrs[:company])
        |> maybe_put(:phone, attrs[:phone])
        |> maybe_put(:email, attrs[:email])
      else
        c
      end
    end)
  end

  defp maybe_put(contact, _key, nil), do: contact
  defp maybe_put(contact, key, value), do: Map.put(contact, key, value)

  @doc """
  Busca por substring case-insensitive em :name, :phone ou :email.
  """
  def search(contacts, field, query)
      when field in [:name, :phone, :email] and is_binary(query) do
    q = String.downcase(query)

    contacts
    |> Enum.filter(fn c ->
      c
      |> Map.get(field)
      |> to_string()
      |> String.downcase()
      |> String.contains?(q)
    end)
  end

  @doc """
  Retorna o contato com o id ou nil.
  """
  def find(contacts, id) when is_list(contacts) do
    Enum.find(contacts, fn c -> c.id == id end)
  end

  @doc """
  Ordena por id para exibição estável.
  """
  def sorted(contacts) do
    Enum.sort_by(contacts, & &1.id)
  end

  @doc """
  Valida email simples (contém @ e partes não vazias).
  """
  def valid_email?(email) when is_binary(email) do
    case String.split(email, "@") do
      [local, domain] ->
        local != "" and domain != "" and String.contains?(domain, ".")

      _ ->
        false
    end
  end

  @doc """
  Valida telefone não vazio (formato livre, ex.: DDD + número).
  """
  def valid_phone?(phone) when is_binary(phone), do: String.trim(phone) != ""
end
