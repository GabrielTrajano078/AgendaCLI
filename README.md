# Agenda CLI

Aplicação de linha de comando em Elixir para gerenciar contatos pessoais, com persistência em JSON (`contacts.json` no diretório de execução).

## Requisitos

- Elixir 1.14 ou superior
- Erlang/OTP compatível

## Instalação

Clone o repositório e instale as dependências:

```bash
git clone https://github.com/GabrielTrajano078/AgendaCLI.git
cd AgendaCLI
mix deps.get
```

## Execução

Inicie o loop interativo com:

```bash
mix run -e "AgendaCli.main([])"
```

O prompt será `agenda> `.

## Comandos

| Comando | Descrição |
|--------|-----------|
| `add --name ... --company ... --phone ... --email ...` | Adiciona contato (id gerado automaticamente). |
| `edit <id> [--name ...] [--company ...] [--phone ...] [--email ...]` | Atualiza um ou mais campos. |
| `del <id>` | Remove o contato. |
| `show <id>` | Exibe todos os campos do contato. |
| `list` | Lista todos os contatos. |
| `search --name <texto>` | Busca parcial e sem diferenciar maiúsculas/minúsculas no nome. |
| `search --phone <texto>` | Idem no telefone. |
| `search --email <texto>` | Idem no email. |
| `exit` | Encerra a aplicação. |

### Exemplos

```text
agenda> add --name Ana Lima --company Acme --phone 85912345678 --email ana.lima@acme.com
agenda> list
agenda> search --name ana
agenda> show 1713531600000
agenda> edit 1713531600000 --phone 85912341234 --company Acme LTDA
agenda> del 1713531600000
agenda> exit
```

Valores com espaços podem ser escritos sem aspas: tudo entre uma flag e a próxima flag `--...` entra no valor do campo.

## Persistência

Os dados são gravados em `contacts.json` após cada operação que altera a lista (`add`, `edit`, `del`). Na inicialização, o arquivo é lido; se não existir, começa-se com lista vazia.

## Estrutura do projeto

- `AgendaCli` — entrada (`main/1`), loop recursivo e despacho de comandos.
- `AgendaCli.Contacts` — funções puras sobre a lista de contatos.
- `AgendaCli.Store` — `load/0` e `save/1` para o JSON (via biblioteca **Jason**).
- `AgendaCli.Parser` — tokenização e parsing de flags / `parse_search/1`.
