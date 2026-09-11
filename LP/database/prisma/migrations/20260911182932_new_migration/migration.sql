-- CreateEnum
CREATE TYPE "tipo_usuario_enum" AS ENUM ('municipe', 'funcionario');

-- CreateEnum
CREATE TYPE "ticket_status_enum" AS ENUM ('aberto', 'em_analise', 'em_andamento', 'pendente', 'resolvido', 'fechado');

-- CreateEnum
CREATE TYPE "ticket_prioridade_enum" AS ENUM ('normal', 'urgente');

-- CreateEnum
CREATE TYPE "solicitacao_status_enum" AS ENUM ('pendente', 'em_analise', 'respondida', 'recusada');

-- CreateEnum
CREATE TYPE "tipo_evento_enum" AS ENUM ('criacao', 'mudanca_status', 'ajuste_prazo', 'atribuicao');

-- CreateEnum
CREATE TYPE "notificacao_tipo_enum" AS ENUM ('novo_ticket', 'nova_solicitacao', 'solicitacao_respondida');

-- CreateEnum
CREATE TYPE "notificacao_canal_enum" AS ENUM ('push', 'email');

-- CreateEnum
CREATE TYPE "notificacao_status_enum" AS ENUM ('pendente', 'enviada', 'falhou', 'lida');

-- CreateTable
CREATE TABLE "secretarias" (
    "id" INTEGER NOT NULL,
    "nome" VARCHAR NOT NULL,
    "sigla" VARCHAR,
    "ativo" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "secretarias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "departamentos" (
    "id" INTEGER NOT NULL,
    "id_secretaria" INTEGER NOT NULL,
    "nome" VARCHAR NOT NULL,
    "sigla" VARCHAR,
    "ativo" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "departamentos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "usuarios" (
    "id" SERIAL NOT NULL,
    "tipo_usuario" "tipo_usuario_enum" NOT NULL DEFAULT 'municipe',
    "nome" VARCHAR,
    "email" VARCHAR,
    "senha_hash" VARCHAR,
    "reservado" BOOLEAN NOT NULL DEFAULT false,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "usuario_departamentos" (
    "id" INTEGER NOT NULL,
    "id_usuario" INTEGER NOT NULL,
    "id_departamento" INTEGER NOT NULL,

    CONSTRAINT "usuario_departamentos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "categorias" (
    "id" INTEGER NOT NULL,
    "id_departamento" INTEGER NOT NULL,
    "nome" VARCHAR NOT NULL,
    "tempo_primeira_resposta_minutos" INTEGER NOT NULL,
    "tempo_maximo_resolucao_minutos" INTEGER NOT NULL,
    "tempo_minimo_resolucao_minutos" INTEGER NOT NULL,
    "tempo_resolucao_urgente_minutos" INTEGER NOT NULL,
    "ativo" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "categorias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "perguntas" (
    "id" INTEGER NOT NULL,
    "id_categoria" INTEGER NOT NULL,
    "enunciado" TEXT NOT NULL,
    "reducao_minutos" INTEGER NOT NULL DEFAULT 0,
    "critica" BOOLEAN NOT NULL DEFAULT false,
    "id_departamento_solicitado" INTEGER,
    "ordem" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "perguntas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tickets" (
    "id" INTEGER NOT NULL,
    "id_usuario" INTEGER NOT NULL,
    "id_categoria" INTEGER NOT NULL,
    "id_departamento" INTEGER NOT NULL,
    "id_funcionario_responsavel" INTEGER,
    "status" "ticket_status_enum" NOT NULL DEFAULT 'aberto',
    "prioridade" "ticket_prioridade_enum" NOT NULL DEFAULT 'normal',
    "descricao" TEXT,
    "geom" geography(Point,4326),
    "token_acesso" VARCHAR,
    "prazo_primeira_resposta_minutos" INTEGER NOT NULL,
    "prazo_resolucao_minutos" INTEGER NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tickets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "respostas" (
    "id" INTEGER NOT NULL,
    "id_pergunta" INTEGER NOT NULL,
    "id_ticket" INTEGER NOT NULL,
    "valor" BOOLEAN NOT NULL,

    CONSTRAINT "respostas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ticket_historico" (
    "id" INTEGER NOT NULL,
    "id_ticket" INTEGER NOT NULL,
    "tipo_evento" "tipo_evento_enum" NOT NULL,
    "status" "ticket_status_enum",
    "prazo_minutos" INTEGER,
    "id_usuario" INTEGER,
    "texto" TEXT,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ticket_historico_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "solicitacoes" (
    "id" INTEGER NOT NULL,
    "id_ticket" INTEGER NOT NULL,
    "id_departamento_solicitado" INTEGER NOT NULL,
    "status" "solicitacao_status_enum" NOT NULL DEFAULT 'pendente',
    "descricao" TEXT NOT NULL,
    "resposta" TEXT,
    "respondido_por" INTEGER,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "respondido_em" TIMESTAMP(6),

    CONSTRAINT "solicitacoes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "solicitacao_mensagens" (
    "id" INTEGER NOT NULL,
    "id_solicitacao" INTEGER NOT NULL,
    "id_usuario" INTEGER NOT NULL,
    "mensagem" TEXT NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "solicitacao_mensagens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "arquivos" (
    "id" INTEGER NOT NULL,
    "id_ticket" INTEGER,
    "id_solicitacao_mensagem" INTEGER,
    "path" VARCHAR NOT NULL,
    "tipo" VARCHAR,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "arquivos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notificacoes" (
    "id" INTEGER NOT NULL,
    "id_usuario" INTEGER NOT NULL,
    "tipo_evento" "notificacao_tipo_enum" NOT NULL,
    "id_ticket" INTEGER,
    "id_solicitacao" INTEGER,
    "canal" "notificacao_canal_enum" NOT NULL DEFAULT 'push',
    "status" "notificacao_status_enum" NOT NULL DEFAULT 'pendente',
    "tentativas" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "enviado_em" TIMESTAMP(6),
    "lido_em" TIMESTAMP(6),

    CONSTRAINT "notificacoes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "logs_auditoria" (
    "id" INTEGER NOT NULL,
    "id_usuario" INTEGER,
    "acao" VARCHAR NOT NULL,
    "entidade_tipo" VARCHAR NOT NULL,
    "entidade_id" INTEGER NOT NULL,
    "dados_antigos" JSONB,
    "dados_novos" JSONB,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "logs_auditoria_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "departamentos_id_secretaria_idx" ON "departamentos"("id_secretaria");

-- CreateIndex
CREATE INDEX "usuario_departamentos_id_departamento_idx" ON "usuario_departamentos"("id_departamento");

-- CreateIndex
CREATE UNIQUE INDEX "usuario_departamentos_id_usuario_id_departamento_key" ON "usuario_departamentos"("id_usuario", "id_departamento");

-- CreateIndex
CREATE INDEX "categorias_id_departamento_idx" ON "categorias"("id_departamento");

-- CreateIndex
CREATE INDEX "perguntas_id_categoria_idx" ON "perguntas"("id_categoria");

-- CreateIndex
CREATE INDEX "perguntas_id_departamento_solicitado_idx" ON "perguntas"("id_departamento_solicitado");

-- CreateIndex
CREATE UNIQUE INDEX "tickets_token_acesso_key" ON "tickets"("token_acesso");

-- CreateIndex
CREATE INDEX "tickets_id_usuario_idx" ON "tickets"("id_usuario");

-- CreateIndex
CREATE INDEX "tickets_id_categoria_idx" ON "tickets"("id_categoria");

-- CreateIndex
CREATE INDEX "tickets_id_departamento_idx" ON "tickets"("id_departamento");

-- CreateIndex
CREATE INDEX "tickets_id_funcionario_responsavel_idx" ON "tickets"("id_funcionario_responsavel");

-- CreateIndex
CREATE INDEX "respostas_id_pergunta_idx" ON "respostas"("id_pergunta");

-- CreateIndex
CREATE INDEX "respostas_id_ticket_idx" ON "respostas"("id_ticket");

-- CreateIndex
CREATE INDEX "ticket_historico_id_ticket_idx" ON "ticket_historico"("id_ticket");

-- CreateIndex
CREATE INDEX "ticket_historico_id_usuario_idx" ON "ticket_historico"("id_usuario");

-- CreateIndex
CREATE INDEX "solicitacoes_id_ticket_idx" ON "solicitacoes"("id_ticket");

-- CreateIndex
CREATE INDEX "solicitacoes_id_departamento_solicitado_idx" ON "solicitacoes"("id_departamento_solicitado");

-- CreateIndex
CREATE INDEX "solicitacoes_respondido_por_idx" ON "solicitacoes"("respondido_por");

-- CreateIndex
CREATE INDEX "solicitacao_mensagens_id_solicitacao_idx" ON "solicitacao_mensagens"("id_solicitacao");

-- CreateIndex
CREATE INDEX "solicitacao_mensagens_id_usuario_idx" ON "solicitacao_mensagens"("id_usuario");

-- CreateIndex
CREATE INDEX "arquivos_id_ticket_idx" ON "arquivos"("id_ticket");

-- CreateIndex
CREATE INDEX "arquivos_id_solicitacao_mensagem_idx" ON "arquivos"("id_solicitacao_mensagem");

-- CreateIndex
CREATE INDEX "notificacoes_id_usuario_idx" ON "notificacoes"("id_usuario");

-- CreateIndex
CREATE INDEX "notificacoes_id_ticket_idx" ON "notificacoes"("id_ticket");

-- CreateIndex
CREATE INDEX "notificacoes_id_solicitacao_idx" ON "notificacoes"("id_solicitacao");

-- CreateIndex
CREATE INDEX "logs_auditoria_id_usuario_idx" ON "logs_auditoria"("id_usuario");

-- AddForeignKey
ALTER TABLE "departamentos" ADD CONSTRAINT "departamentos_id_secretaria_fkey" FOREIGN KEY ("id_secretaria") REFERENCES "secretarias"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "usuario_departamentos" ADD CONSTRAINT "usuario_departamentos_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "usuario_departamentos" ADD CONSTRAINT "usuario_departamentos_id_departamento_fkey" FOREIGN KEY ("id_departamento") REFERENCES "departamentos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categorias" ADD CONSTRAINT "categorias_id_departamento_fkey" FOREIGN KEY ("id_departamento") REFERENCES "departamentos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "perguntas" ADD CONSTRAINT "perguntas_id_categoria_fkey" FOREIGN KEY ("id_categoria") REFERENCES "categorias"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "perguntas" ADD CONSTRAINT "perguntas_id_departamento_solicitado_fkey" FOREIGN KEY ("id_departamento_solicitado") REFERENCES "departamentos"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_id_categoria_fkey" FOREIGN KEY ("id_categoria") REFERENCES "categorias"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_id_departamento_fkey" FOREIGN KEY ("id_departamento") REFERENCES "departamentos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_id_funcionario_responsavel_fkey" FOREIGN KEY ("id_funcionario_responsavel") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "respostas" ADD CONSTRAINT "respostas_id_pergunta_fkey" FOREIGN KEY ("id_pergunta") REFERENCES "perguntas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "respostas" ADD CONSTRAINT "respostas_id_ticket_fkey" FOREIGN KEY ("id_ticket") REFERENCES "tickets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ticket_historico" ADD CONSTRAINT "ticket_historico_id_ticket_fkey" FOREIGN KEY ("id_ticket") REFERENCES "tickets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ticket_historico" ADD CONSTRAINT "ticket_historico_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitacoes" ADD CONSTRAINT "solicitacoes_id_ticket_fkey" FOREIGN KEY ("id_ticket") REFERENCES "tickets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitacoes" ADD CONSTRAINT "solicitacoes_id_departamento_solicitado_fkey" FOREIGN KEY ("id_departamento_solicitado") REFERENCES "departamentos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitacoes" ADD CONSTRAINT "solicitacoes_respondido_por_fkey" FOREIGN KEY ("respondido_por") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitacao_mensagens" ADD CONSTRAINT "solicitacao_mensagens_id_solicitacao_fkey" FOREIGN KEY ("id_solicitacao") REFERENCES "solicitacoes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "solicitacao_mensagens" ADD CONSTRAINT "solicitacao_mensagens_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "arquivos" ADD CONSTRAINT "arquivos_id_ticket_fkey" FOREIGN KEY ("id_ticket") REFERENCES "tickets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "arquivos" ADD CONSTRAINT "arquivos_id_solicitacao_mensagem_fkey" FOREIGN KEY ("id_solicitacao_mensagem") REFERENCES "solicitacao_mensagens"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notificacoes" ADD CONSTRAINT "notificacoes_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notificacoes" ADD CONSTRAINT "notificacoes_id_ticket_fkey" FOREIGN KEY ("id_ticket") REFERENCES "tickets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notificacoes" ADD CONSTRAINT "notificacoes_id_solicitacao_fkey" FOREIGN KEY ("id_solicitacao") REFERENCES "solicitacoes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "logs_auditoria" ADD CONSTRAINT "logs_auditoria_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;
