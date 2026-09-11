-- DropForeignKey
ALTER TABLE "arquivos" DROP CONSTRAINT "arquivos_id_solicitacao_mensagem_fkey";

-- DropForeignKey
ALTER TABLE "arquivos" DROP CONSTRAINT "arquivos_id_ticket_fkey";

-- DropForeignKey
ALTER TABLE "categorias" DROP CONSTRAINT "categorias_id_departamento_fkey";

-- DropForeignKey
ALTER TABLE "departamentos" DROP CONSTRAINT "departamentos_id_secretaria_fkey";

-- DropForeignKey
ALTER TABLE "logs_auditoria" DROP CONSTRAINT "logs_auditoria_id_usuario_fkey";

-- DropForeignKey
ALTER TABLE "notificacoes" DROP CONSTRAINT "notificacoes_id_solicitacao_fkey";

-- DropForeignKey
ALTER TABLE "notificacoes" DROP CONSTRAINT "notificacoes_id_ticket_fkey";

-- DropForeignKey
ALTER TABLE "notificacoes" DROP CONSTRAINT "notificacoes_id_usuario_fkey";

-- DropForeignKey
ALTER TABLE "perguntas" DROP CONSTRAINT "perguntas_id_categoria_fkey";

-- DropForeignKey
ALTER TABLE "perguntas" DROP CONSTRAINT "perguntas_id_departamento_solicitado_fkey";

-- DropForeignKey
ALTER TABLE "respostas" DROP CONSTRAINT "respostas_id_pergunta_fkey";

-- DropForeignKey
ALTER TABLE "respostas" DROP CONSTRAINT "respostas_id_ticket_fkey";

-- DropForeignKey
ALTER TABLE "solicitacao_mensagens" DROP CONSTRAINT "solicitacao_mensagens_id_solicitacao_fkey";

-- DropForeignKey
ALTER TABLE "solicitacao_mensagens" DROP CONSTRAINT "solicitacao_mensagens_id_usuario_fkey";

-- DropForeignKey
ALTER TABLE "solicitacoes" DROP CONSTRAINT "solicitacoes_id_departamento_solicitado_fkey";

-- DropForeignKey
ALTER TABLE "solicitacoes" DROP CONSTRAINT "solicitacoes_id_ticket_fkey";

-- DropForeignKey
ALTER TABLE "solicitacoes" DROP CONSTRAINT "solicitacoes_respondido_por_fkey";

-- DropForeignKey
ALTER TABLE "ticket_historico" DROP CONSTRAINT "ticket_historico_id_ticket_fkey";

-- DropForeignKey
ALTER TABLE "ticket_historico" DROP CONSTRAINT "ticket_historico_id_usuario_fkey";

-- DropForeignKey
ALTER TABLE "tickets" DROP CONSTRAINT "tickets_id_categoria_fkey";

-- DropForeignKey
ALTER TABLE "tickets" DROP CONSTRAINT "tickets_id_departamento_fkey";

-- DropForeignKey
ALTER TABLE "tickets" DROP CONSTRAINT "tickets_id_funcionario_responsavel_fkey";

-- DropForeignKey
ALTER TABLE "tickets" DROP CONSTRAINT "tickets_id_usuario_fkey";

-- DropForeignKey
ALTER TABLE "usuario_departamentos" DROP CONSTRAINT "usuario_departamentos_id_departamento_fkey";

-- DropForeignKey
ALTER TABLE "usuario_departamentos" DROP CONSTRAINT "usuario_departamentos_id_usuario_fkey";

-- CreateIndex
CREATE INDEX "arquivos_id_ticket_idx" ON "arquivos"("id_ticket");

-- CreateIndex
CREATE INDEX "arquivos_id_solicitacao_mensagem_idx" ON "arquivos"("id_solicitacao_mensagem");

-- CreateIndex
CREATE INDEX "categorias_id_departamento_idx" ON "categorias"("id_departamento");

-- CreateIndex
CREATE INDEX "departamentos_id_secretaria_idx" ON "departamentos"("id_secretaria");

-- CreateIndex
CREATE INDEX "logs_auditoria_id_usuario_idx" ON "logs_auditoria"("id_usuario");

-- CreateIndex
CREATE INDEX "notificacoes_id_usuario_idx" ON "notificacoes"("id_usuario");

-- CreateIndex
CREATE INDEX "notificacoes_id_ticket_idx" ON "notificacoes"("id_ticket");

-- CreateIndex
CREATE INDEX "notificacoes_id_solicitacao_idx" ON "notificacoes"("id_solicitacao");

-- CreateIndex
CREATE INDEX "perguntas_id_categoria_idx" ON "perguntas"("id_categoria");

-- CreateIndex
CREATE INDEX "perguntas_id_departamento_solicitado_idx" ON "perguntas"("id_departamento_solicitado");

-- CreateIndex
CREATE INDEX "respostas_id_pergunta_idx" ON "respostas"("id_pergunta");

-- CreateIndex
CREATE INDEX "respostas_id_ticket_idx" ON "respostas"("id_ticket");

-- CreateIndex
CREATE INDEX "solicitacao_mensagens_id_solicitacao_idx" ON "solicitacao_mensagens"("id_solicitacao");

-- CreateIndex
CREATE INDEX "solicitacao_mensagens_id_usuario_idx" ON "solicitacao_mensagens"("id_usuario");

-- CreateIndex
CREATE INDEX "solicitacoes_id_ticket_idx" ON "solicitacoes"("id_ticket");

-- CreateIndex
CREATE INDEX "solicitacoes_id_departamento_solicitado_idx" ON "solicitacoes"("id_departamento_solicitado");

-- CreateIndex
CREATE INDEX "solicitacoes_respondido_por_idx" ON "solicitacoes"("respondido_por");

-- CreateIndex
CREATE INDEX "ticket_historico_id_ticket_idx" ON "ticket_historico"("id_ticket");

-- CreateIndex
CREATE INDEX "ticket_historico_id_usuario_idx" ON "ticket_historico"("id_usuario");

-- CreateIndex
CREATE INDEX "tickets_id_usuario_idx" ON "tickets"("id_usuario");

-- CreateIndex
CREATE INDEX "tickets_id_categoria_idx" ON "tickets"("id_categoria");

-- CreateIndex
CREATE INDEX "tickets_id_departamento_idx" ON "tickets"("id_departamento");

-- CreateIndex
CREATE INDEX "tickets_id_funcionario_responsavel_idx" ON "tickets"("id_funcionario_responsavel");

-- CreateIndex
CREATE INDEX "usuario_departamentos_id_departamento_idx" ON "usuario_departamentos"("id_departamento");

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
