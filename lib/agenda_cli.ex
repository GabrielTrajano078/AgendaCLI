defmodule AgendaCli do
  @moduledoc """
  Ponto de entrada, loop interativo (recursão de cauda) e despacho de comandos.
  """

  alias AgendaCli.{Contacts, Parser, Store}

  @doc """
  Inicia a CLI. Uso: `mix run -e "AgendaCli.main([])"`
  """
  def main(_args \\ []) do
    IO.puts("Agenda de contatos. Digite `exit` para sair.")
    Store.load() |> loop()
  end

  defp loop(contacts) do
    case IO.gets("agenda> ") do
      :eof ->
        IO.puts("")
        :ok

      line ->
        line
        |> handle_line(contacts)
        |> cont_or_halt()
    end
  end

  defp cont_or_halt({:halt, _contacts}), do: :ok

  defp cont_or_halt({:continue, next_contacts}) do
    next_contacts
    |> loop()
  end

  defp handle_line(line, contacts) do
    line
    |> Parser.tokenize()
    |> dispatch(contacts)
  end

  defp dispatch([], contacts), do: err(contacts, "Comando vazio.")

  defp dispatch(["exit"], contacts), do: {:halt, contacts}

  defp dispatch(["exit" | _], contacts), do: {:halt, contacts}

  defp dispatch(["list"], contacts) do
    contacts
    |> Contacts.sorted()
    |> format_list()
    |> IO.puts()

    {:continue, contacts}
  end

  defp dispatch(["list" | _], contacts),
    do: err(contacts, "Uso: list")

  defp dispatch(["show", id_str], contacts) do
    with {:ok, id} <- parse_id(id_str) do
      case Contacts.find(contacts, id) do
        nil ->
          err(contacts, "Contato não encontrado.")

        c ->
          IO.puts(format_contact(c))
          {:continue, contacts}
      end
    else
      _ -> err(contacts, "Uso: show <id> (id inteiro).")
    end
  end

  defp dispatch(["show" | _], contacts),
    do: err(contacts, "Uso: show <id>")

  defp dispatch(["add" | rest], contacts) do
    {flags, leftover} = Parser.parse_flags(rest)

    cond do
      leftover != [] ->
        err(contacts, "Argumentos inválidos após flags do add.")

      not Map.has_key?(flags, :name) or not Map.has_key?(flags, :company) or
          not Map.has_key?(flags, :phone) or not Map.has_key?(flags, :email) ->
        err(
          contacts,
          "Uso: add --name ... --company ... --phone ... --email ..."
        )

      flags.name == "" or flags.company == "" or flags.phone == "" or flags.email == "" ->
        err(contacts, "Nenhum campo pode ser vazio.")

      not Contacts.valid_phone?(flags.phone) ->
        err(contacts, "Telefone inválido.")

      not Contacts.valid_email?(flags.email) ->
        err(contacts, "Email inválido.")

      true ->
        new_contacts =
          contacts
          |> Contacts.add(%{
            name: flags.name,
            company: flags.company,
            phone: flags.phone,
            email: flags.email
          })

        Store.save(new_contacts)
        IO.puts("Contato adicionado (id #{hd(new_contacts).id}).")
        {:continue, new_contacts}
    end
  end

  defp dispatch(["del", id_str], contacts) do
    with {:ok, id} <- parse_id(id_str) do
      case Contacts.find(contacts, id) do
        nil ->
          err(contacts, "Contato não encontrado.")

        _ ->
          new_contacts = Contacts.delete(contacts, id)
          Store.save(new_contacts)
          IO.puts("Contato removido.")
          {:continue, new_contacts}
      end
    else
      _ -> err(contacts, "Uso: del <id>")
    end
  end

  defp dispatch(["del" | _], contacts), do: err(contacts, "Uso: del <id>")

  defp dispatch(["edit", id_str | rest], contacts) do
    with {:ok, id} <- parse_id(id_str) do
      {flags, leftover} = Parser.parse_flags(rest)

      cond do
        leftover != [] ->
          err(contacts, "Argumentos inválidos após flags do edit.")

        map_size(flags) == 0 ->
          err(contacts, "Informe ao menos uma flag: --name, --company, --phone, --email.")

        Contacts.find(contacts, id) == nil ->
          err(contacts, "Contato não encontrado.")

        flags[:name] == "" or flags[:company] == "" or flags[:phone] == "" or flags[:email] == "" ->
          err(contacts, "Valores vazios não são permitidos.")

        flags[:phone] && not Contacts.valid_phone?(flags[:phone]) ->
          err(contacts, "Telefone inválido.")

        flags[:email] && not Contacts.valid_email?(flags[:email]) ->
          err(contacts, "Email inválido.")

        true ->
          new_contacts = Contacts.edit(contacts, id, flags)
          Store.save(new_contacts)
          IO.puts("Contato atualizado.")
          {:continue, new_contacts}
      end
    else
      _ -> err(contacts, "Uso: edit <id> [--name ...] [--company ...] ...")
    end
  end

  defp dispatch(["edit" | _], contacts),
    do: err(contacts, "Uso: edit <id> [flags]")

  defp dispatch(["search" | rest], contacts) do
    case Parser.parse_search(rest) do
      :error ->
        err(contacts, "Uso: search --name <texto> | --phone <texto> | --email <texto>")

      {field, value} ->
        contacts
        |> Contacts.search(field, value)
        |> Contacts.sorted()
        |> format_list()
        |> IO.puts()

        {:continue, contacts}
    end
  end

  defp dispatch([unknown | _], contacts) do
    err(contacts, "Comando desconhecido: #{unknown}")
  end

  defp err(contacts, msg) do
    IO.puts("Erro: #{msg}")
    {:continue, contacts}
  end

  defp parse_id(str) do
    case Integer.parse(str) do
      {id, ""} -> {:ok, id}
      _ -> :error
    end
  end

  defp format_contact(c) do
    """
    id: #{c.id}
    name: #{c.name}
    company: #{c.company}
    phone: #{c.phone}
    email: #{c.email}
    """
    |> String.trim_trailing()
  end

  defp format_list([]), do: "(nenhum contato)"

  defp format_list(contacts) do
    contacts
    |> Enum.map(fn c ->
      "#{c.id}\t#{c.name}\t#{c.company}\t#{c.phone}\t#{c.email}"
    end)
    |> Enum.join("\n")
  end
end
