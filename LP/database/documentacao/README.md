# Manual do Desenvolvedor: Configuração e Fluxo de Trabalho

## 1. Fluxo de Trabalho do Desenvolvedor (Passo a Passo)

**Cenário de Exemplo:** O PO criou a Issue `#12`, gerou a branch `feat/12-botao-entrar` no repositório remoto e atribuiu a tarefa a você.

### Passo 1: Atualizar as referências locais
Atualize as branches remotas no seu Git local:
```bash
git fetch --all
```

### Passo 2: Acessar a branch da tarefa
Acesse a branch já criada pelo PO (não utilize a flag `-b`):
```bash
git checkout feat/12-botao-entrar
```

### Passo 3: Desenvolvimento e Testes Locais

## 3.1. Configurando o Ambiente Local

### Pré-requisitos no seu computador
* Instalar o **Node.js** (versão 20 ou superior).
* Instalar o **Docker Desktop** (mantenha-o aberto rodando em segundo plano).
* Instalar a extensão **Prisma** no VS Code para auto-completar e formatar o código.

### Passos de Configuração:
1. No terminal, baixe as dependências do projeto:
```bash
npm install
```

2. Crie o arquivo `.env` a partir do modelo base `.env.example`:
```bash
cp .env.example .env
```

3. Configure a variável de conexão no arquivo `.env`. 
URL padrão configurada no Docker:
```env
DATABASE_URL="postgresql://admin:adminpassword@localhost:5432/lab_praticas?schema=public"
```
Caso queira configurar com credenciais personalizadas:
```env
DATABASE_URL="postgresql://SEU_USUARIO:SUA_SENHA@localhost:5432/lab_praticas?schema=public"
```

4. Suba o container do banco de dados local via Docker:
```bash
docker-compose up -d
```

5. Aplique o código abaixo para sincronizar as migrations com o banco:
```bash
npx prisma migrate dev
```

### Visualização do Banco de Dados
Para visualizar e gerenciar o banco de dados graficamente, utilize um cliente SQL (como **SQLPro for Postgres**, **DBeaver** ou **pgAdmin**).

Com o container ativo, conecte-se utilizando as credenciais padrão do `.env`:
* **Server / Host:** `localhost`
* **Port:** `5432`
* **Database:** `lab_praticas`
* **Login / Username:** `admin`
* **Password:** `adminpassword`

 6. Após as alterações necessárias:
   -  Formatar o arquivo de schema:
      Garante que a indentação e os espaçamentos estejam nos conformes da pipeline de CI.
         ```bash
         npx prisma format
         ```

   - Criar a nova Migration e aplicar no banco local:
     Gera o arquivo SQL com a alteração feita e aplica diretamente no PostgreSQL do Docker. Substitua o nome pela alteração realizada:
        ```bash
        npx prisma migrate dev --name adiciona_campo_telefone
        ```

   - Regenerar o Prisma Client (se for programar no código da aplicação):
     Atualiza os tipos e os métodos do TypeScript/Node.js com base nas novas tabelas criadas:
        ```bash
        npx prisma generate
        ```

---

3. **Verificação de Alterações Indesejadas:**
   Certifique-se de que arquivos de dependências (`package.json` ou `package-lock.json`) não sofreram alterações acidentais:
   ```bash
   git status
   ```

### Passo 4: Realizar o Commit
Adicione os arquivos alterados e registre a mensagem seguindo o padrão de commits convencionais:
```bash
git add .
git commit -m "feat: cria a modelagem de usuarios e migration correspondente"
```

### Passo 5: Enviar as alterações e abrir o Pull Request
Envie o commit para a branch remota:
```bash
git push origin feat/12-botao-entrar
```

**No GitHub:**
1. Clique em **Compare & pull request**.
2. Garanta que a branch base de destino está apontada para a branch correta definida pelo PO (ex: `base: epic/login` <- `compare: feat/12-botao-entrar`).
3. Na descrição do Pull Request, inclua o comando de fechamento referenciando o número da issue:
   ```markdown
   Closes #12
   ```
4. Submeta o Pull Request e aguarde a validação automatizada das GitHub Actions.
