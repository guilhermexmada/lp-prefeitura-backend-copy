# Migrations e seed por ambiente

## Objetivo

O banco separa a estrutura necessária pela aplicação dos dados fictícios de desenvolvimento:

```text
prisma/
├── migrations/
│   └── 20260910172256_tickets_registro/
│       └── migration.sql  # Estrutura: PostGIS, enums, tabelas, índices e FKs
├── schema.prisma          # Mapeamento Prisma da estrutura
└── seed.sql               # Dados de exemplo, apenas para desenvolvimento
```

`migration.sql` não contém `INSERT`. Por isso, pode ser aplicada tanto em desenvolvimento quanto em produção. `seed.sql` contém os registros de exemplo e nunca deve ser executado em produção.

## Desenvolvimento local

### 1. Subir o PostgreSQL

No diretório `database`:

```powershell
docker compose up -d
```

### 2. Aplicar a estrutura

```powershell
npx.cmd prisma migrate dev
```

Em um banco vazio, esse comando cria extensão PostGIS, enums, tabelas, índices e relacionamentos. Ele não cria os tickets de exemplo.

### 3. Carregar os dados de desenvolvimento

O seed é SQL puro e é carregado pelo `psql` que já existe no container Docker:

```powershell
docker cp .\prisma\seed.sql praticas-db-local:/tmp/seed.sql
docker compose exec postgres psql -U admin -d lab_praticas -v ON_ERROR_STOP=1 -f /tmp/seed.sql
```

O script começa com `TRUNCATE TABLE secretarias CASCADE`; portanto, ele remove os dados atuais das tabelas do sistema antes de inserir o cenário de exemplo. Execute-o somente em uma base local descartável.

Para conferir a carga:

```powershell
docker compose exec postgres psql -U admin -d lab_praticas -c "SELECT COUNT(*) AS total_tickets FROM tickets;"
```

O cenário atual contém cinco tickets.

## Produção

Na produção, aplique somente as migrations:

```powershell
npx prisma migrate deploy
```

Não copie nem execute `prisma/seed.sql`. Os dados reais devem ser criados pela aplicação ou por processos aprovados de importação.

## Alterações futuras

- Mudanças de estrutura (tabelas, colunas, índices, enums ou constraints) exigem uma nova migration Prisma.
- Novos exemplos e ajustes nos dados fictícios devem ser feitos apenas em `prisma/seed.sql`.
- Nunca edite uma migration já aplicada em um ambiente compartilhado ou em produção.
- Antes de alterar o seed, considere que ele deve continuar inserindo registros compatíveis com as constraints definidas nas migrations.

## Fluxo resumido

| Ambiente | Estrutura | Dados de exemplo |
| --- | --- | --- |
| Desenvolvimento | `npx prisma migrate dev` | Executar `prisma/seed.sql` manualmente no container |
| Produção | `npx prisma migrate deploy` | Nunca executar |
