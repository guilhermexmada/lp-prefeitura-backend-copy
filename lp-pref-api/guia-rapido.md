# Guia Rápido — Subir o banco, atualizar o schema e criar rotas CRUD

Guia enxuto para o dia a dia. Para contexto completo (decisões, troubleshooting), ver `setup-banco-dados-docker-prisma.md`.

## 1. Subir os containers

No repositório `database`:
```bash
docker-compose up -d
```

Confirme que subiu:
```bash
docker-compose ps
```

`.env` do backend (porta padrão, sem conflito — serviço nativo do Windows desabilitado):
```dotenv
DATABASE_URL="postgresql://admin:adminpassword@localhost:5432/lab_praticas?schema=public"
```

## 2. Atualizar o schema

Sempre que uma tabela mudar, no repositório `database`:

```bash
npx prisma format
npx prisma migrate dev --name <descricao_da_mudanca>
```

`prisma format` normaliza indentação/espaçamento do `schema.prisma` (exigido pela pipeline de CI). `migrate dev` gera o arquivo SQL da mudança e aplica no banco local.

No repositório backend, depois de sincronizar o `schema.prisma` atualizado:
```bash
pnpm exec prisma generate
```
Isso regenera o Prisma Client com os tipos/métodos atualizados — necessário antes de usar qualquer campo/tabela nova no código.

## 3. Rotas CRUD — exemplo com `usuarios`

Modelagem real da tabela (sem alterações):
```prisma
model usuarios {
  id            Int               @id
  tipo_usuario  tipo_usuario_enum @default(municipe)
  nome          String?           @db.VarChar
  email         String?           @db.VarChar
  senha_hash    String?           @db.VarChar
  reservado     Boolean           @default(false)
  ativo         Boolean           @default(true)
  created_at    DateTime          @default(now())
}
```

⚠️ **`id` não tem autoincrement** — é `Int` puro, sem `@default(autoincrement())`. Por isso, diferente do que você normalmente veria em outros projetos Prisma, o `POST` abaixo **exige que o `id` venha no corpo da requisição** — o banco não gera esse valor sozinho.

```typescript
import { Router } from 'express';
import { prisma } from '../lib/prisma';

const router = Router();

// GET /usuarios — listar todos
router.get('/usuarios', async (_req, res) => {
  const usuarios = await prisma.usuarios.findMany();
  res.json(usuarios);
});

// GET /usuarios/:id — buscar um
router.get('/usuarios/:id', async (req, res) => {
  const usuario = await prisma.usuarios.findUnique({
    where: { id: Number(req.params.id) },
  });
  if (!usuario) return res.status(404).json({ error: 'Usuário não encontrado' });
  res.json(usuario);
});

// POST /usuarios — criar
router.post('/usuarios', async (req, res) => {
  const { id, tipo_usuario, nome, email, senha_hash } = req.body;
  const usuario = await prisma.usuarios.create({
    data: { id, tipo_usuario, nome, email, senha_hash },
  });
  res.status(201).json(usuario);
});

// PUT /usuarios/:id — atualizar
router.put('/usuarios/:id', async (req, res) => {
  const { nome, email, senha_hash, ativo } = req.body;
  const usuario = await prisma.usuarios.update({
    where: { id: Number(req.params.id) },
    data: { nome, email, senha_hash, ativo },
  });
  res.json(usuario);
});

// DELETE /usuarios/:id — remover
router.delete('/usuarios/:id', async (req, res) => {
  await prisma.usuarios.delete({
    where: { id: Number(req.params.id) },
  });
  res.status(204).send();
});

export default router;
```

Sem tratamento de erro (`try/catch`) de propósito, pra manter o exemplo focado no CRUD em si — em rotas reais, envolva cada handler num `try/catch` (ou num middleware de erro do Express) antes de ir pra produção.

### Testando

```bash
curl -X POST http://localhost:3000/usuarios -H "Content-Type: application/json" -d '{"id": 1, "nome": "Teste", "email": "teste@exemplo.com"}'
curl http://localhost:3000/usuarios
curl -X PUT http://localhost:3000/usuarios/1 -H "Content-Type: application/json" -d '{"nome": "Teste Atualizado"}'
curl -X DELETE http://localhost:3000/usuarios/1
```
