-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "plpgsql" WITH SCHEMA "pg_catalog" VERSION "1.0";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "public" VERSION "3.4.3";

-- CreateEnum
CREATE TYPE "public"."notificacao_canal_enum" AS ENUM ('push', 'email');

-- CreateEnum
CREATE TYPE "public"."notificacao_status_enum" AS ENUM ('pendente', 'enviada', 'falhou', 'lida');

-- CreateEnum
CREATE TYPE "public"."notificacao_tipo_enum" AS ENUM ('novo_ticket', 'nova_solicitacao', 'solicitacao_respondida');

-- CreateEnum
CREATE TYPE "public"."solicitacao_status_enum" AS ENUM ('pendente', 'em_analise', 'respondida', 'recusada');

-- CreateEnum
CREATE TYPE "public"."ticket_prioridade_enum" AS ENUM ('normal', 'urgente');

-- CreateEnum
CREATE TYPE "public"."ticket_status_enum" AS ENUM ('aberto', 'em_analise', 'em_andamento', 'pendente', 'resolvido', 'fechado');

-- CreateEnum
CREATE TYPE "public"."tipo_evento_enum" AS ENUM ('criacao', 'mudanca_status', 'ajuste_prazo', 'atribuicao');

-- CreateEnum
CREATE TYPE "public"."tipo_usuario_enum" AS ENUM ('municipe', 'funcionario');

-- CreateTable
CREATE TABLE "public"."arquivos" (
    "id" INTEGER NOT NULL,
    "id_ticket" INTEGER,
    "id_solicitacao_mensagem" INTEGER,
    "path" VARCHAR NOT NULL,
    "tipo" VARCHAR,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "arquivos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."categorias" (
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
CREATE TABLE "public"."departamentos" (
    "id" INTEGER NOT NULL,
    "id_secretaria" INTEGER NOT NULL,
    "nome" VARCHAR NOT NULL,
    "sigla" VARCHAR,
    "ativo" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "departamentos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."logs_auditoria" (
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

-- CreateTable
CREATE TABLE "public"."notificacoes" (
    "id" INTEGER NOT NULL,
    "id_usuario" INTEGER NOT NULL,
    "tipo_evento" "public"."notificacao_tipo_enum" NOT NULL,
    "id_ticket" INTEGER,
    "id_solicitacao" INTEGER,
    "canal" "public"."notificacao_canal_enum" NOT NULL DEFAULT 'push',
    "status" "public"."notificacao_status_enum" NOT NULL DEFAULT 'pendente',
    "tentativas" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "enviado_em" TIMESTAMP(6),
    "lido_em" TIMESTAMP(6),

    CONSTRAINT "notificacoes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."perguntas" (
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
CREATE TABLE "public"."respostas" (
    "id" INTEGER NOT NULL,
    "id_pergunta" INTEGER NOT NULL,
    "id_ticket" INTEGER NOT NULL,
    "valor" BOOLEAN NOT NULL,

    CONSTRAINT "respostas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."secretarias" (
    "id" INTEGER NOT NULL,
    "nome" VARCHAR NOT NULL,
    "sigla" VARCHAR,
    "ativo" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "secretarias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."solicitacao_mensagens" (
    "id" INTEGER NOT NULL,
    "id_solicitacao" INTEGER NOT NULL,
    "id_usuario" INTEGER NOT NULL,
    "mensagem" TEXT NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "solicitacao_mensagens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."solicitacoes" (
    "id" INTEGER NOT NULL,
    "id_ticket" INTEGER NOT NULL,
    "id_departamento_solicitado" INTEGER NOT NULL,
    "status" "public"."solicitacao_status_enum" NOT NULL DEFAULT 'pendente',
    "descricao" TEXT NOT NULL,
    "resposta" TEXT,
    "respondido_por" INTEGER,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "respondido_em" TIMESTAMP(6),

    CONSTRAINT "solicitacoes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."ticket_historico" (
    "id" INTEGER NOT NULL,
    "id_ticket" INTEGER NOT NULL,
    "tipo_evento" "public"."tipo_evento_enum" NOT NULL,
    "status" "public"."ticket_status_enum",
    "prazo_minutos" INTEGER,
    "id_usuario" INTEGER,
    "texto" TEXT,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ticket_historico_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."tickets" (
    "id" INTEGER NOT NULL,
    "id_usuario" INTEGER NOT NULL,
    "id_categoria" INTEGER NOT NULL,
    "id_departamento" INTEGER NOT NULL,
    "id_funcionario_responsavel" INTEGER,
    "status" "public"."ticket_status_enum" NOT NULL DEFAULT 'aberto',
    "prioridade" "public"."ticket_prioridade_enum" NOT NULL DEFAULT 'normal',
    "descricao" TEXT,
    "geom" geography,
    "token_acesso" VARCHAR,
    "prazo_primeira_resposta_minutos" INTEGER NOT NULL,
    "prazo_resolucao_minutos" INTEGER NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tickets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."usuario_departamentos" (
    "id" INTEGER NOT NULL,
    "id_usuario" INTEGER NOT NULL,
    "id_departamento" INTEGER NOT NULL,

    CONSTRAINT "usuario_departamentos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."usuarios" (
    "id" INTEGER NOT NULL,
    "tipo_usuario" "public"."tipo_usuario_enum" NOT NULL DEFAULT 'municipe',
    "nome" VARCHAR,
    "email" VARCHAR,
    "senha_hash" VARCHAR,
    "reservado" BOOLEAN NOT NULL DEFAULT false,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "tickets_token_acesso_key" ON "public"."tickets"("token_acesso" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "usuario_departamentos_id_usuario_id_departamento_key" ON "public"."usuario_departamentos"("id_usuario" ASC, "id_departamento" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "uq_usuarios_unico_reservado" ON "public"."usuarios"("reservado" ASC) WHERE (reservado = true);

-- AddForeignKey
ALTER TABLE "public"."arquivos" ADD CONSTRAINT "arquivos_id_solicitacao_mensagem_fkey" FOREIGN KEY ("id_solicitacao_mensagem") REFERENCES "public"."solicitacao_mensagens"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."arquivos" ADD CONSTRAINT "arquivos_id_ticket_fkey" FOREIGN KEY ("id_ticket") REFERENCES "public"."tickets"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."categorias" ADD CONSTRAINT "categorias_id_departamento_fkey" FOREIGN KEY ("id_departamento") REFERENCES "public"."departamentos"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."departamentos" ADD CONSTRAINT "departamentos_id_secretaria_fkey" FOREIGN KEY ("id_secretaria") REFERENCES "public"."secretarias"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."logs_auditoria" ADD CONSTRAINT "logs_auditoria_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "public"."usuarios"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."notificacoes" ADD CONSTRAINT "notificacoes_id_solicitacao_fkey" FOREIGN KEY ("id_solicitacao") REFERENCES "public"."solicitacoes"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."notificacoes" ADD CONSTRAINT "notificacoes_id_ticket_fkey" FOREIGN KEY ("id_ticket") REFERENCES "public"."tickets"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."notificacoes" ADD CONSTRAINT "notificacoes_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "public"."usuarios"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."perguntas" ADD CONSTRAINT "perguntas_id_categoria_fkey" FOREIGN KEY ("id_categoria") REFERENCES "public"."categorias"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."perguntas" ADD CONSTRAINT "perguntas_id_departamento_solicitado_fkey" FOREIGN KEY ("id_departamento_solicitado") REFERENCES "public"."departamentos"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."respostas" ADD CONSTRAINT "respostas_id_pergunta_fkey" FOREIGN KEY ("id_pergunta") REFERENCES "public"."perguntas"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."respostas" ADD CONSTRAINT "respostas_id_ticket_fkey" FOREIGN KEY ("id_ticket") REFERENCES "public"."tickets"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."solicitacao_mensagens" ADD CONSTRAINT "solicitacao_mensagens_id_solicitacao_fkey" FOREIGN KEY ("id_solicitacao") REFERENCES "public"."solicitacoes"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."solicitacao_mensagens" ADD CONSTRAINT "solicitacao_mensagens_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "public"."usuarios"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."solicitacoes" ADD CONSTRAINT "solicitacoes_id_departamento_solicitado_fkey" FOREIGN KEY ("id_departamento_solicitado") REFERENCES "public"."departamentos"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."solicitacoes" ADD CONSTRAINT "solicitacoes_id_ticket_fkey" FOREIGN KEY ("id_ticket") REFERENCES "public"."tickets"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."solicitacoes" ADD CONSTRAINT "solicitacoes_respondido_por_fkey" FOREIGN KEY ("respondido_por") REFERENCES "public"."usuarios"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."ticket_historico" ADD CONSTRAINT "ticket_historico_id_ticket_fkey" FOREIGN KEY ("id_ticket") REFERENCES "public"."tickets"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."ticket_historico" ADD CONSTRAINT "ticket_historico_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "public"."usuarios"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."tickets" ADD CONSTRAINT "tickets_id_categoria_fkey" FOREIGN KEY ("id_categoria") REFERENCES "public"."categorias"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."tickets" ADD CONSTRAINT "tickets_id_departamento_fkey" FOREIGN KEY ("id_departamento") REFERENCES "public"."departamentos"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."tickets" ADD CONSTRAINT "tickets_id_funcionario_responsavel_fkey" FOREIGN KEY ("id_funcionario_responsavel") REFERENCES "public"."usuarios"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."tickets" ADD CONSTRAINT "tickets_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "public"."usuarios"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."usuario_departamentos" ADD CONSTRAINT "usuario_departamentos_id_departamento_fkey" FOREIGN KEY ("id_departamento") REFERENCES "public"."departamentos"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "public"."usuario_departamentos" ADD CONSTRAINT "usuario_departamentos_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "public"."usuarios"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

