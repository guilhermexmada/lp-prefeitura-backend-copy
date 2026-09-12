# lp-prefeitura-backend-copy

## Início rápido

```
# 1. clonar repositorio 
git clone https://github.com/guilhermexmada/lp-prefeitura-backend-copy.git

# 2. baixar dependências do database
cd lp-prefeitura-backend-copy/lp/database
npm install

# 3. criar .env
<copiar .env.example>

# 4. subir container com docker
docker compose up -d

# 5. aplicar new_migration existente (inclui correção do auto_increment no user.id)
npx prisma migrate deploy

# 6. gera prisma client no repo backend
npx prisma generate

# 7. baixar dependências do backend
cd..
cd backend
npm install

# 8. criar .env
<copiar .env.example>

# 9. rodar backend
npm run dev

# resultado esperado

> backend-api@1.0.0 dev
> tsx watch src/server.ts

HTTP server running on http://localhost:3000
```

## Requisições para testar (via insomnia por ex.)

```
Cadastro de usuário
http://localhost:3000/api/user/register

{
  "nome": "Fulano Ciclano da Silva",
  "email": "email@exemplo.com",
  "senha": "senha123"
}

Login de usuário
http://localhost:3000/api/user/login

{
  "email": "email@exemplo.com",
  "senha": "senha123"
}

```

## Pendências para implementar nos repositórios oficiais do github

- Alterar schema.prisma do repositório database: adicionar auto_increment() em todos os IDs
- Igualar versão das dependências do Prisma entre database e backend
- Refatorar rotas de register e login adicionando comentários mínimos
- Padronizar nome da model de usuários (está User enquanto as outras estão em português)
- Corrigir conflito de .env entre database e backend que impede de abrir o prisma studio
