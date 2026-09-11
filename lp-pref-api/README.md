# Setup Docker + Postgres + Prisma

Este documento registra como configuramos, conectamos e populamos o banco de dados do projeto, e o por que de cada decisão técnica.

**Status:** ambiente funcional de ponta a ponta (Docker → Postgres/PostGIS → Prisma → Express)

---

## 1. Arquitetura

- API REST em Node.js
- Linguagem: TypeScript
- Framework: Express
- Gerenciador de pacotes: pnpm
- Banco: PostgreSQL 16 com extensão PostGIS 3.4
- Conteinerização: Docker (imagem `postgis/postgis:16-3.4`)
- ORM: Prisma **7.10.0** (ver [Decisão 2](#decisão-2-versão-do-prisma))
- Administração visual do banco: pgAdmin (via Docker imagem `dpage/pgadmin4`)

---

## 2. Decisões técnicas

### Decisão 1 — SQL como fonte de verdade

O projeto já tinha um script `seed.sql` escrito à mão, contendo tabelas, enums, FKs, CHECKs, índices únicos e coluna geoespacial PostGIS. Algumas dessas estruturas não são totalmente nativas da linguagem de schema do Prisma.

**Decisão:** Os containers do banco foram criados usando `seed.sql` via Docker, tornando-se a fonte de verdade. O Prisma no backend **nunca roda migrations** - ele é usado em modo de **introspecção** (`prisma db pull`), lendo o banco já existente e gerando um client TypeScript tipado a partir dele.

### Decisão 2 — Versão do Prisma

Tentamos inicialmente o **Prisma 8**, por ser a versão mais recente disponível via `pnpm add -D prisma` (sem fixar versão). Batemos em três problemas de infraestrutura:

1. **A CLI mudou de formato entre versões.** `prisma init --datasource-provider postgresql` foi substituído no Prisma 8, que traz um paradigma baseado em "contracts" ao invés de `schema.prisma` + `PrismaClient`.

2. **Erro `CLI.CONFIG_UNREADABLE`** ao tentar `prisma contract infer`, com a mensagem `No "exports" main defined` num pacote interno (`@prisma/cli-engine`).

3. **Confirmando causa raiz:** o pacote `prisma` (CLI) e o pacote `@prisma/orm-postgres` (conector de Postgres do Prisma 8) estavam com versões fora de sincronia — o primeiro publicado até `8.0.0-rc.13`, o segundo travado em `8.0.0-rc.9`. Ou seja, **não existe hoje uma combinação coerente de pacotes do Prisma 8 para Postgres**.

**Decisão:** fixar a versão em **Prisma 7.10.0** (última versão estável, Prisma 8 está em Release Candidate)

---

## 3. Pré-requisitos

- Docker Desktop instalado e rodando
- Node.js >= v20.0.0 e pnpm instalados
- Nenhum outro serviço Postgres competindo pela porta usada no host (ver [seção 6.6](#66-conflito-de-porta-com-postgres-nativo-do-windows))

---

## 4. `docker-compose.yml`

**Localização no repositório:** `docker-compose.yml` e `seed.sql` devem estar na **raiz do repositório**, lado a lado.

---

## 5. Passo a passo (setup do zero)

### 5.1 Subir o banco

```bash
docker compose up -d
```

Confirmar que subiu:
```bash
docker compose ps
```

Confirmar que o schema populou:
```bash
docker exec -it lp_database_db psql -U postgres -d lp-database -c "\dt"
```
Deve listar as 15 tabelas do domínio (`secretarias`, `departamentos`, `tickets`, `usuarios`, etc.) — não só `spatial_ref_sys` e os schemas `tiger`/`topology` (esses últimos são internos do PostGIS e aparecem em qualquer inicialização).

Se as tabelas do domínio não aparecerem, ou se o container não subir, ver [seção 6](#6-erros-enfrentados-causas-e-soluções) antes de seguir.

### 5.2 Instalar o Prisma (versão fixada)

```bash
pnpm add prisma@7.10.0 @types/node @types/pg --save-dev
pnpm add @prisma/client@7.10.0 @prisma/adapter-pg pg dotenv
```

Se aparecer `ERR_PNPM_IGNORED_BUILDS`, ver [seção 6.7](#66-err_pnpm_ignored_builds).

| Pacote | Papel |
|---|---|
| `prisma` | CLI (comandos `init`, `db pull`, `generate`) — só em dev |
| `@prisma/client` | Biblioteca runtime importada no código |
| `@prisma/adapter-pg` | Driver adapter — conecta o Prisma Client ao Postgres via `node-postgres` |
| `pg` | Driver `node-postgres`, usado por baixo do adapter |
| `dotenv` | Carrega o `.env` (não é mais automático a partir do Prisma 7) |

### 5.3 Inicializar

```bash
pnpm exec prisma init --datasource-provider postgresql --output ../src/generated/prisma
```

Usamos `pnpm exec` (não `pnpm dlx`) para garantir que o binário local, fixado em 7.10.0, seja o executado — `dlx` poderia resolver para a versão `latest` (Prisma 8).

O `--output ../src/generated/prisma` define onde o client gerado vai morar. **Isso é diferente do padrão sugerido inicialmente** (`../generated/prisma`, na raiz do projeto) — ver o motivo em [seção 6.8](#78-rootdir-do-typescript-e-localização-do-client-gerado).

Isso cria `prisma/schema.prisma`, `.env` e `prisma.config.ts`.

### 5.4 Configurar `prisma.config.ts`

```typescript
import "dotenv/config";
import { defineConfig, env } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
  },
  datasource: {
    url: env("DATABASE_URL"),
  },
});
```

A partir do Prisma 7, a `DATABASE_URL` não fica mais escrita no `schema.prisma` — é lida aqui, via `env("DATABASE_URL")`.

### 5.5 `.env`

```dotenv
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/lp-database?schema=public"
```

Os componentes vêm diretamente do `docker-compose.yml`: usuário/senha de `POSTGRES_USER`/`POSTGRES_PASSWORD`, porta de `ports` (lado do host), nome do banco de `POSTGRES_DB`.

### 5.6 Habilitar PostGIS e índices parciais no schema

Editar `prisma/schema.prisma`:
```prisma
generator client {
  provider        = "prisma-client"
  output          = "../src/generated/prisma"
  previewFeatures = ["postgresqlExtensions", "partialIndexes"]
}

datasource db {
  provider   = "postgresql"
  extensions = [postgis]
}
```

- `postgresqlExtensions` — permite o Prisma reconhecer a extensão `postgis` habilitada no banco.
- `partialIndexes` — permite representar corretamente o índice único parcial de `usuarios.reservado` (o `db pull`, na prática, já ativa essa flag sozinho quando detecta a necessidade).

### 5.7 Introspecção

```bash
pnpm exec prisma db pull
```

Lê o Postgres real e escreve os `model`s/`enum`s em `schema.prisma`. Saída esperada (resumo):

```
√ Introspected 15 models and wrote them into prisma\schema.prisma

*** WARNING ***
These fields are not supported by Prisma Client...
  - Model: "tickets", field: "geom", original data type: "geography"

These constraints are not supported by Prisma Client...
  - Model: "arquivos", constraint: "chk_arquivo_dono_unico"
  - Model: "perguntas", constraint: "perguntas_reducao_minutos_check"
  - Model: "spatial_ref_sys", constraint: "spatial_ref_sys_srid_check"
```

**Esses avisos são esperados e não são erro:**

- **IDs sem `@default(autoincrement())`** em todas as tabelas — o SQL original define as PKs como `INTEGER` puro, sem `SERIAL`/`IDENTITY`. Na prática, todo `create()` precisa fornecer o `id` manualmente; o banco não gera automaticamente.
- **`tickets.geom` vira `Unsupported("geography")`** — o Prisma não modela nativamente tipos PostGIS. O Postgres continua validando/armazenando normalmente; só o Prisma Client não consegue ler/escrever esse campo via API normal (`findMany`, `create`, etc. simplesmente ignoram o campo). Acesso via `$queryRaw`/`$executeRaw` — ver [Pendências](#pendências).
- **`CHECK` constraints não aparecem no schema** — o Postgres continua aplicando essas regras; o Prisma só não as representa, então uma violação só é percebida em runtime (erro vindo do Postgres), não em tempo de compilação.
- **`spatial_ref_sys`** é uma tabela interna do próprio PostGIS (não é do domínio da aplicação) — aparece por estar no schema `public`. Pode ser ignorada/removida do `schema.prisma` a cada `db pull` sem efeito colateral (volta a aparecer na próxima introspecção).
- **Relações duplicadas** (ex: `tickets` tem duas FKs para `usuarios` — `id_usuario` e `id_funcionario_responsavel`) geram nomes de relação automáticos e pouco legíveis (`usuarios_tickets_id_funcionario_responsavelTousuarios`). Funcionam normalmente; renomear via `@relation("nome")` é só cosmético.
- **Índice único parcial** (`usuarios.reservado`) foi corretamente representado como `@unique(map: "...", where: raw("(reservado = true)"))` — o Prisma Client garante essa constraint em nível de tipo, não só o Postgres.

### 5.8 Gerar o Prisma Client

```bash
pnpm exec prisma generate
```

### 5.9 Instanciar o client com o adapter

`src/lib/prisma.ts`:
```typescript
import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../generated/prisma/client.js';

const connectionString = `${process.env.DATABASE_URL}`;

const adapter = new PrismaPg({ connectionString });
const prisma = new PrismaClient({ adapter });

export { prisma };
```

- O `.js` no import (mesmo apontando para um arquivo `.ts`) é exigido porque o `package.json` do projeto tem `"type": "module"` — assim o Node resolve módulos ESM corretamente em runtime.
- Diferente de versões anteriores do Prisma, aqui a conexão é montada manualmente: cria-se o `adapter` (via `@prisma/adapter-pg`) e ele é passado no construtor do `PrismaClient`.
- Manter essa instância centralizada num único módulo evita abrir múltiplos pools de conexão (o que aconteceria se cada rota instanciasse seu próprio `PrismaClient`).

### 5.10 Validar com um script isolado (opcional, recomendado)

Útil para confirmar a conexão **antes** de integrar no Express — isola se um problema é do Prisma/banco ou do Express.

`script.ts` na raiz do projeto:
```typescript
import { prisma } from './src/lib/prisma';

async function main() {
  const departamentos = await prisma.departamentos.findMany({
    where: { ativo: true },
  });
  console.log(departamentos);
}

main()
  .then(async () => { await prisma.$disconnect(); })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
```

```bash
pnpm exec tsx script.ts
```

Esperado: os departamentos de exemplo no console. Arquivo descartável após validar — não faz parte da aplicação.

### 5.11 Rota de health-check

```typescript
import { prisma } from './lib/prisma';

app.get('/health', async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.status(200).json({ status: 'ok', database: 'up' });
  } catch (error) {
    console.error('Health check falhou:', error);
    res.status(503).json({ status: 'error', database: 'down' });
  }
});
```

- `SELECT 1` é a query mais barata possível — confirma que o Postgres respondeu, sem depender de dado específico existir em nenhuma tabela.
- Em caso de falha, a rota responde `503 Service Unavailable` (não `200`) — é o código correto para "servidor no ar, dependência indisponível", e é o que ferramentas de monitoramento/orquestração esperam para identificar o problema.

Teste manual do caminho de falha:
```bash
docker compose stop db
curl -i http://localhost:3000/health   # deve retornar 503
docker compose start db
```

---

## 6. Resolução de Erros

Histórico de troubleshooting real do projeto, para referência futura.

### 6.1 `Is a directory` ao subir o container

**Sintoma:** `psql:/docker-entrypoint-initdb.d/seed.sql: error: could not read from input file: Is a directory`

**Causa:** na hora do `docker compose up`, o Compose não encontrou `seed.sql` no caminho relativo esperado (não estava ao lado do `docker-compose.yml`) e, em vez de dar erro na hora, criou uma **pasta vazia** com esse nome no host — comportamento padrão do Docker para bind mounts apontando a um caminho inexistente.

**Solução:** confirmar que `seed.sql` está fisicamente ao lado do `docker-compose.yml`; remover a pasta fantasma criada (`rmdir seed.sql`, se vazia); resetar o volume (`docker compose down -v`) e subir de novo.

### 6.2 Tabelas do domínio não aparecem (só `spatial_ref_sys`/`tiger`/`topology`)

**Causa:** `docker-entrypoint-initdb.d` só executa na primeira inicialização de um volume **vazio**. Se o container já tinha subido antes (mesmo que o `seed.sql` estivesse errado/ausente nessa primeira vez), o volume fica marcado como inicializado e passa a ignorar a pasta de scripts em qualquer subida futura — mesmo depois de corrigir o `seed.sql`.

**Solução:** `docker compose down -v` (o `-v` remove também o volume nomeado) seguido de `docker compose up -d`.

### 6.3 `prisma init --datasource-provider` não reconhecido (Prisma 8)

**Causa:** mudança de CLI entre versões — o Prisma 8 substituiu esse comando por `prisma orm init --target postgres`, dentro do novo paradigma de "contracts". Ver [Decisão 2](#decisão-2-versão-do-prisma).

### 6.4 `CLI.CONFIG_UNREADABLE` / `No "exports" main defined` (Prisma 8)

**Causa:** descompasso de versões publicadas entre `prisma` e `@prisma/orm-postgres` no registro do npm, causando resolução de duas versões incompatíveis de um pacote interno (`@prisma/cli-engine`) na árvore de dependências do pnpm. Confirmado via `npm view <pacote> dist-tags`. Ver [Decisão 2](#decisão-2-versão-do-prisma).

**Solução:** abandonar o Prisma 8 RC, fixar Prisma 7.10.0.

### 6.5 `prisma.config.ts` renomeado para `prisma7.config.ts`

**Causa:** ao limpar os arquivos do Prisma 8 (antes de reinstalar o v7), o `prisma.config.ts` antigo (na raiz do projeto, fora da pasta `prisma/`) não foi removido junto. Ao rodar `prisma init` do v7, a CLI encontrou um arquivo existente com esse nome e, para não sobrescrever às cegas, salvou o novo config sob outro nome.

**Solução:** remover o `prisma.config.ts` antigo e renomear o novo (`prisma7.config.ts` → `prisma.config.ts`).

### 6.6 Conflito de porta com Postgres nativo do Windows

**Sintoma:** `Error: P1000 — Authentication failed against database server` ao rodar `prisma db pull`, mesmo com usuário/senha corretos.

**Diagnóstico:**
```powershell
netstat -ano | findstr :5432
tasklist /FI "PID eq <pid>"
```
Revelou **dois processos** escutando na porta `5432`: o container Docker e um `postgres.exe` rodando como serviço nativo do Windows (resquício de instalação anterior). A conexão do Prisma estava sendo roteada para o Postgres nativo — que tem credenciais diferentes — daí o erro de autenticação (não relacionado a nome de usuário/senha estarem "errados" no sentido literal).

**Solução escolhida:** via Powershell, fechar serviço do `postgres.exe` que estava ocupando a porta 5432.

### 6.7 `ERR_PNPM_IGNORED_BUILDS`

**Causa:** versões recentes do pnpm bloqueiam por padrão a execução de build scripts (`postinstall`) de dependências, por segurança. O `prisma`/`@prisma/engines` precisam rodar esse script para baixar os binários do query engine.

**Solução:**
```bash
pnpm approve-builds
# selecionar prisma e @prisma/engines
pnpm install
```

### 6.8 `rootDir` do TypeScript e localização do client gerado

**Sintoma:** `File '.../generated/prisma/client.ts' is not under 'rootDir' '.../src'`

**Causa:** o `tsconfig.json` do projeto define `rootDir: "src"`. O Prisma Client gerado, inicialmente configurado para `../generated/prisma` (raiz do projeto, fora de `src/`), ficava fora dessa fronteira — o TypeScript não conseguia incluir esse arquivo no grafo de compilação respeitando o `rootDir` declarado.

**Solução:** gerar o client dentro de `src/`, em vez de alargar o `rootDir` (evita mudar a estrutura de saída/`dist` do projeto):
```prisma
generator client {
  output = "../src/generated/prisma"
}
```
Com o `.gitignore` cobrindo `generated/` (sem barra inicial), o padrão continua valendo em qualquer profundidade, incluindo `src/generated/`.

### 6.9 Containers duplicados ao mudar de pasta

**Sintoma:** `docker compose up` funcionava normalmente rodando de uma pasta separada (fora do repositório), mas falhava ao rodar a partir da raiz do repositório com os mesmos arquivos.

**Causa:** os containers da pasta separada (`lp_database_db`, `lp_database_pgadmin`) ainda estavam em execução. `container_name` e `ports` precisam ser únicos no Docker **globalmente no sistema**, não por pasta — subir uma segunda cópia do mesmo compose, de outro lugar, colide com os nomes/portas já em uso pelos containers antigos.

**Solução:** `docker compose down` na pasta antiga antes de subir a cópia no repositório. Adicionalmente, fixamos `name: lp-database` no `docker-compose.yml` (ver [seção 4](#4-docker-composeyml-versão-final)) para eliminar a dependência do nome da pasta na definição do nome do volume.
