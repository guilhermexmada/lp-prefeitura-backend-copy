# lp-database — Sistema de Tickets (Prefeitura de Registro/SP)

Banco de dados PostgreSQL + PostGIS, já populado com dados de exemplo, pronto pra rodar via Docker.

## O que tem nessa pasta

| Arquivo | O que é |
|---|---|
| `docker-compose.yml` | Sobe o banco (Postgres + PostGIS) e uma interface visual (pgAdmin) |
| `seed.sql` | Schema completo (tabelas, enums, constraints) + dados de exemplo |
| `README.md` | Este arquivo |

## Pré-requisito

Ter o **Docker Desktop instalado e aberto** (rodando em segundo plano — procura o ícone da baleia na barra de tarefas/bandeja do sistema). Sem ele aberto, o comando abaixo não funciona.

## Como rodar

1. Abra um terminal **dentro dessa pasta** (os três arquivos precisam estar juntos, no mesmo lugar).
2. Rode:
   ```
   docker compose up -d
   ```
3. Na primeira vez, o Docker baixa as imagens (Postgres+PostGIS e pgAdmin) e já carrega o `seed.sql` sozinho, sem precisar rodar nada manualmente depois. Pode levar 1–2 minutos dependendo da internet.
4. Pra conferir se já terminou, rode:
   ```
   docker compose logs db
   ```
   Quando aparecer uma linha tipo `database system is ready to accept connections`, está pronto.

## Como visualizar os dados

1. Abra o navegador em **http://localhost:5050**
2. Entre com:
   - E-mail: `admin@admin.com`
   - Senha: `admin`
3. Clique com o botão direito em **Servers** → **Register** → **Server**
4. Na aba **General**, dê um nome qualquer (ex: `lp-database`)
5. Na aba **Connection**, preencha:
   - Host name/address: `db`
   - Port: `5432`
   - Username: `postgres`
   - Password: `postgres`
6. Depois de conectar, expanda: `Databases` → `lp-database` → `Schemas` → `public` → `Tables`
7. Clique com o botão direito em qualquer tabela → **View/Edit Data** → **All Rows**

## Conferir direto pelo terminal (sem abrir o pgAdmin)

```
docker exec -it lp_database_db psql -U postgres -d lp-database -c "SELECT id, status, prioridade FROM tickets;"
```

## Resetar o banco do zero

O `seed.sql` só roda automaticamente **na primeira vez** que o volume de dados é criado. Se você editar o `seed.sql` e quiser recarregar tudo do zero:

```
docker compose down -v
docker compose up -d
```

O `-v` apaga o volume de dados — sem ele, o Postgres já vai existir com dados antigos e o script novo não vai rodar de novo.

## Parar o banco (sem apagar os dados)

```
docker compose down
```

Da próxima vez que rodar `docker compose up -d`, os dados continuam lá.

## Sobre as tabelas `spatial_ref_sys` e `geometry_columns`

Se você ver essas duas tabelas na lista junto com as suas, é normal — elas são criadas automaticamente pela extensão **PostGIS** (usada pra guardar a localização dos tickets) e não fazem parte do modelo de dados do projeto. Pode ignorar.

## Se der erro ao rodar `docker compose up -d`

- **`unable to get image ... open //./pipe/dockerDesktopLinuxEngine`** → o Docker Desktop não está aberto. Abra o aplicativo, espere o ícone da baleia terminar de carregar, e rode o comando de novo.
- **Porta já em uso (5432 ou 5050)** → provavelmente já tem outro Postgres ou pgAdmin rodando na sua máquina nessa porta. Pode trocar, por exemplo, `"5432:5432"` para `"5433:5432"` no `docker-compose.yml`, e conectar na porta 5433 a partir do seu computador (dentro do Docker continua sendo 5432).
