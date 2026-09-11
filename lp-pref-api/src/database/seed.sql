-- ==========================================================
-- SISTEMA DE TICKETS — Secretaria de Infraestrutura
-- Prefeitura de Registro/SP
-- Schema + banco de exemplo populado
-- ==========================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- ----------------------------------------------------------
-- ENUMS
-- ----------------------------------------------------------

CREATE TYPE tipo_usuario_enum AS ENUM ('municipe', 'funcionario');

CREATE TYPE ticket_status_enum AS ENUM (
  'aberto', 'em_analise', 'em_andamento', 'pendente', 'resolvido', 'fechado'
);

CREATE TYPE ticket_prioridade_enum AS ENUM ('normal', 'urgente');

CREATE TYPE solicitacao_status_enum AS ENUM (
  'pendente', 'em_analise', 'respondida', 'recusada'
);

CREATE TYPE tipo_evento_enum AS ENUM (
  'criacao', 'mudanca_status', 'ajuste_prazo', 'atribuicao'
);

CREATE TYPE notificacao_tipo_enum AS ENUM (
  'novo_ticket', 'nova_solicitacao', 'solicitacao_respondida'
);

CREATE TYPE notificacao_canal_enum AS ENUM ('push', 'email');

CREATE TYPE notificacao_status_enum AS ENUM (
  'pendente', 'enviada', 'falhou', 'lida'
);

-- ----------------------------------------------------------
-- TABELAS
-- ----------------------------------------------------------

CREATE TABLE secretarias (
  id       INTEGER PRIMARY KEY,
  nome     VARCHAR NOT NULL,
  sigla    VARCHAR,
  ativo    BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE departamentos (
  id             INTEGER PRIMARY KEY,
  id_secretaria  INTEGER NOT NULL REFERENCES secretarias(id),
  nome           VARCHAR NOT NULL,
  sigla          VARCHAR,
  ativo          BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE usuarios (
  id           INTEGER PRIMARY KEY,
  tipo_usuario tipo_usuario_enum NOT NULL DEFAULT 'municipe',
  nome         VARCHAR,
  email        VARCHAR,
  senha_hash   VARCHAR,
  reservado    BOOLEAN NOT NULL DEFAULT FALSE,
  ativo        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMP NOT NULL DEFAULT now()
);
-- Só pode existir UMA linha reservada (usuário anônimo compartilhado)
CREATE UNIQUE INDEX uq_usuarios_unico_reservado ON usuarios (reservado) WHERE reservado = TRUE;

CREATE TABLE usuario_departamentos (
  id               INTEGER PRIMARY KEY,
  id_usuario       INTEGER NOT NULL REFERENCES usuarios(id),
  id_departamento  INTEGER NOT NULL REFERENCES departamentos(id),
  UNIQUE (id_usuario, id_departamento)
);

CREATE TABLE categorias (
  id                                INTEGER PRIMARY KEY,
  id_departamento                   INTEGER NOT NULL REFERENCES departamentos(id),
  nome                              VARCHAR NOT NULL,
  tempo_primeira_resposta_minutos   INTEGER NOT NULL,
  tempo_maximo_resolucao_minutos    INTEGER NOT NULL,
  tempo_minimo_resolucao_minutos    INTEGER NOT NULL,
  tempo_resolucao_urgente_minutos   INTEGER NOT NULL,
  ativo                             BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE perguntas (
  id                          INTEGER PRIMARY KEY,
  id_categoria                INTEGER NOT NULL REFERENCES categorias(id),
  enunciado                   TEXT NOT NULL,
  reducao_minutos             INTEGER NOT NULL DEFAULT 0 CHECK (reducao_minutos >= 0),
  critica                     BOOLEAN NOT NULL DEFAULT FALSE,
  id_departamento_solicitado  INTEGER REFERENCES departamentos(id),
  ordem                       INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE tickets (
  id                              INTEGER PRIMARY KEY,
  id_usuario                      INTEGER NOT NULL REFERENCES usuarios(id),
  id_categoria                    INTEGER NOT NULL REFERENCES categorias(id),
  id_departamento                 INTEGER NOT NULL REFERENCES departamentos(id),
  id_funcionario_responsavel      INTEGER REFERENCES usuarios(id),
  status                          ticket_status_enum NOT NULL DEFAULT 'aberto',
  prioridade                      ticket_prioridade_enum NOT NULL DEFAULT 'normal',
  descricao                       TEXT,
  geom                            GEOGRAPHY(Point, 4326),
  token_acesso                    VARCHAR UNIQUE,
  prazo_primeira_resposta_minutos INTEGER NOT NULL,
  prazo_resolucao_minutos         INTEGER NOT NULL,
  created_at                      TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE respostas (
  id           INTEGER PRIMARY KEY,
  id_pergunta  INTEGER NOT NULL REFERENCES perguntas(id),
  id_ticket    INTEGER NOT NULL REFERENCES tickets(id),
  valor        BOOLEAN NOT NULL
);

-- id_usuario é NULLABLE: NULL = ação automática do sistema
-- (ex: mudança de status ao abrir/reverter uma solicitação sozinho)
CREATE TABLE ticket_historico (
  id            INTEGER PRIMARY KEY,
  id_ticket     INTEGER NOT NULL REFERENCES tickets(id),
  tipo_evento   tipo_evento_enum NOT NULL,
  status        ticket_status_enum,
  prazo_minutos INTEGER,
  id_usuario    INTEGER REFERENCES usuarios(id),
  texto         TEXT,
  created_at    TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE solicitacoes (
  id                          INTEGER PRIMARY KEY,
  id_ticket                   INTEGER NOT NULL REFERENCES tickets(id),
  id_departamento_solicitado  INTEGER NOT NULL REFERENCES departamentos(id),
  status                      solicitacao_status_enum NOT NULL DEFAULT 'pendente',
  descricao                   TEXT NOT NULL,
  resposta                    TEXT,
  respondido_por              INTEGER REFERENCES usuarios(id),
  created_at                  TIMESTAMP NOT NULL DEFAULT now(),
  respondido_em               TIMESTAMP
);

CREATE TABLE solicitacao_mensagens (
  id               INTEGER PRIMARY KEY,
  id_solicitacao   INTEGER NOT NULL REFERENCES solicitacoes(id),
  id_usuario       INTEGER NOT NULL REFERENCES usuarios(id),
  mensagem         TEXT NOT NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT now()
);

-- arquivo pertence a EXATAMENTE um dono: o ticket (foto de abertura)
-- ou uma mensagem do chat entre departamentos — nunca os dois, nunca nenhum
CREATE TABLE arquivos (
  id                       INTEGER PRIMARY KEY,
  id_ticket                INTEGER REFERENCES tickets(id),
  id_solicitacao_mensagem  INTEGER REFERENCES solicitacao_mensagens(id),
  path                     VARCHAR NOT NULL,
  tipo                     VARCHAR,
  created_at               TIMESTAMP NOT NULL DEFAULT now(),
  CONSTRAINT chk_arquivo_dono_unico CHECK (
    (id_ticket IS NOT NULL AND id_solicitacao_mensagem IS NULL) OR
    (id_ticket IS NULL AND id_solicitacao_mensagem IS NOT NULL)
  )
);

CREATE TABLE notificacoes (
  id             INTEGER PRIMARY KEY,
  id_usuario     INTEGER NOT NULL REFERENCES usuarios(id),
  tipo_evento    notificacao_tipo_enum NOT NULL,
  id_ticket      INTEGER REFERENCES tickets(id),
  id_solicitacao INTEGER REFERENCES solicitacoes(id),
  canal          notificacao_canal_enum NOT NULL DEFAULT 'push',
  status         notificacao_status_enum NOT NULL DEFAULT 'pendente',
  tentativas     INTEGER NOT NULL DEFAULT 0,
  created_at     TIMESTAMP NOT NULL DEFAULT now(),
  enviado_em     TIMESTAMP,
  lido_em        TIMESTAMP
);

CREATE TABLE logs_auditoria (
  id             INTEGER PRIMARY KEY,
  id_usuario     INTEGER REFERENCES usuarios(id),
  acao           VARCHAR NOT NULL,
  entidade_tipo  VARCHAR NOT NULL,
  entidade_id    INTEGER NOT NULL,
  dados_antigos  JSONB,
  dados_novos    JSONB,
  created_at     TIMESTAMP NOT NULL DEFAULT now()
);

-- ==========================================================
-- DADOS DE EXEMPLO
-- ==========================================================

-- ---------- SECRETARIA E DEPARTAMENTOS ----------

INSERT INTO secretarias (id, nome, sigla) VALUES
  (1, 'Secretaria Municipal de Infraestrutura e Serviços Públicos', 'SISP');

INSERT INTO departamentos (id, id_secretaria, nome, sigla) VALUES
  (1, 1, 'Vias e Pavimentação', 'VIAS'),
  (2, 1, 'Poda e Arborização Urbana', 'PODA'),
  (3, 1, 'Bueiros e Drenagem', 'DRENAGEM');

-- ---------- USUÁRIOS ----------

-- linha reservada de usuário anônimo (nunca apagar)
INSERT INTO usuarios (id, tipo_usuario, nome, email, senha_hash, reservado) VALUES
  (1, 'municipe', NULL, NULL, NULL, TRUE);

-- munícipes identificados
INSERT INTO usuarios (id, tipo_usuario, nome, email, senha_hash) VALUES
  (2, 'municipe', 'Maria Aparecida da Silva', 'maria.silva@example.com', 'hash_exemplo_2'),
  (3, 'municipe', 'João Pedro Santos',        'joao.santos@example.com', 'hash_exemplo_3');

-- funcionários
INSERT INTO usuarios (id, tipo_usuario, nome, email, senha_hash) VALUES
  (4, 'funcionario', 'Carlos Eduardo Ramos',  'carlos.ramos@registro.sp.gov.br',  'hash_exemplo_4'),
  (5, 'funcionario', 'Fernanda Lima Costa',   'fernanda.lima@registro.sp.gov.br', 'hash_exemplo_5'),
  (6, 'funcionario', 'Roberto Alves Souza',   'roberto.souza@registro.sp.gov.br', 'hash_exemplo_6'),
  (7, 'funcionario', 'Juliana Pereira Nunes', 'juliana.nunes@registro.sp.gov.br', 'hash_exemplo_7');

-- vínculo funcionário x departamento (Roberto atua em 2 departamentos)
INSERT INTO usuario_departamentos (id, id_usuario, id_departamento) VALUES
  (1, 4, 1), -- Carlos    -> Vias
  (2, 5, 2), -- Fernanda  -> Poda
  (3, 6, 1), -- Roberto   -> Vias
  (4, 6, 3), -- Roberto   -> Drenagem (mesmo funcionário, 2 departamentos)
  (5, 7, 3); -- Juliana   -> Drenagem

-- ---------- CATEGORIAS ----------

INSERT INTO categorias
  (id, id_departamento, nome, tempo_primeira_resposta_minutos, tempo_maximo_resolucao_minutos, tempo_minimo_resolucao_minutos, tempo_resolucao_urgente_minutos)
VALUES
  (1, 1, 'Buraco na via',            1440, 10080, 720,  1440), -- resp 24h / máx 7d / mín 12h / urgente 24h
  (2, 2, 'Poda de árvore',           2880, 20160, 1440, 1440), -- resp 48h / máx 14d / mín 24h / urgente 24h
  (3, 3, 'Bueiro entupido/alagamento', 720, 4320,  360,  360); -- resp 12h / máx 3d / mín 6h / urgente 6h

-- ---------- PERGUNTAS ----------

-- categoria 1: Buraco na via
INSERT INTO perguntas (id, id_categoria, enunciado, reducao_minutos, critica, id_departamento_solicitado, ordem) VALUES
  (1, 1, 'O buraco causa risco de acidente (queda/colisão)?',         0,    TRUE,  NULL, 1),
  (2, 1, 'O buraco bloqueia a via total ou parcialmente?',            2880, FALSE, NULL, 2),
  (3, 1, 'O problema existe há mais de 1 mês?',                       1440, FALSE, NULL, 3),
  (4, 1, 'Há raiz de árvore aparente causando o problema?',           0,    FALSE, 2,    4); -- aciona solicitação p/ Poda

-- categoria 2: Poda de árvore
INSERT INTO perguntas (id, id_categoria, enunciado, reducao_minutos, critica, id_departamento_solicitado, ordem) VALUES
  (5, 2, 'A árvore/galho está prestes a cair sobre residência ou rede elétrica?', 0,    TRUE,  NULL, 1),
  (6, 2, 'A árvore está bloqueando via ou calçada?',                             1440, FALSE, 1,    2), -- aciona solicitação p/ Vias (sinalização)
  (7, 2, 'O galho já caiu no chão?',                                             720,  FALSE, NULL, 3);

-- categoria 3: Bueiro entupido
INSERT INTO perguntas (id, id_categoria, enunciado, reducao_minutos, critica, id_departamento_solicitado, ordem) VALUES
  (8, 3, 'Há risco de alagamento imediato de residências?', 0,   TRUE,  NULL, 1),
  (9, 3, 'A água já está transbordando pra rua?',            180, FALSE, NULL, 2);

-- ==========================================================
-- TICKET 1 — fluxo simples, munícipe identificado, sem urgência,
-- funcionário assume e coloca em andamento
-- ==========================================================

INSERT INTO tickets
  (id, id_usuario, id_categoria, id_departamento, id_funcionario_responsavel, status, prioridade,
   descricao, geom, token_acesso, prazo_primeira_resposta_minutos, prazo_resolucao_minutos, created_at)
VALUES
  (1, 2, 1, 1, 4, 'em_andamento', 'normal',
   'Buraco grande na Rua XV de Novembro, próximo ao número 450.',
   ST_GeogFromText('SRID=4326;POINT(-47.8455 -24.4838)'),
   NULL, 1440, 7200, -- pergunta 2 = sim (2880) => 10080-2880=7200
   '2026-08-20 09:12:00');

INSERT INTO respostas (id, id_pergunta, id_ticket, valor) VALUES
  (1, 1, 1, FALSE),
  (2, 2, 1, TRUE),
  (3, 3, 1, FALSE),
  (4, 4, 1, FALSE);

INSERT INTO ticket_historico (id, id_ticket, tipo_evento, status, prazo_minutos, id_usuario, texto, created_at) VALUES
  (1, 1, 'criacao',       'aberto',       7200, 2, NULL,                                            '2026-08-20 09:12:00'),
  (2, 1, 'mudanca_status','em_analise',   NULL, 4, 'Primeira visita realizada, confirmado o buraco.', '2026-08-20 14:30:00'),
  (3, 1, 'atribuicao',    NULL,           NULL, 4, 'Assumiu o chamado para execução do reparo.',      '2026-08-21 08:00:00'),
  (4, 1, 'mudanca_status','em_andamento', NULL, 4, 'Equipe iniciou o reparo do buraco.',               '2026-08-21 08:05:00');

INSERT INTO arquivos (id, id_ticket, path, tipo, created_at) VALUES
  (1, 1, '/uploads/tickets/1/foto_abertura_1.jpg', 'foto_abertura', '2026-08-20 09:12:00');

-- ==========================================================
-- TICKET 2 — munícipe anônimo, pergunta crítica = urgente,
-- ciclo completo até resolvido
-- ==========================================================

INSERT INTO tickets
  (id, id_usuario, id_categoria, id_departamento, id_funcionario_responsavel, status, prioridade,
   descricao, geom, token_acesso, prazo_primeira_resposta_minutos, prazo_resolucao_minutos, created_at)
VALUES
  (2, 1, 1, 1, 6, 'resolvido', 'urgente',
   'Buraco profundo na Av. Jurumirim, causou queda de motociclista ontem à noite.',
   ST_GeogFromText('SRID=4326;POINT(-47.8501 -24.4901)'),
   'a1b2c3d4e5f647a89b0c1d2e3f4a5b6c', 1440, 1440, -- crítico => usa tempo_resolucao_urgente_minutos
   '2026-08-22 07:03:00');

INSERT INTO respostas (id, id_pergunta, id_ticket, valor) VALUES
  (5, 1, 2, TRUE),  -- crítica: risco de acidente
  (6, 2, 2, TRUE),
  (7, 3, 2, FALSE),
  (8, 4, 2, FALSE);

INSERT INTO ticket_historico (id, id_ticket, tipo_evento, status, prazo_minutos, id_usuario, texto, created_at) VALUES
  (5, 2, 'criacao',       'aberto',       1440, 1, NULL,                                          '2026-08-22 07:03:00'),
  (6, 2, 'mudanca_status','em_analise',   NULL, 4, 'Risco confirmado no local, prioridade alta.',  '2026-08-22 08:00:00'),
  (7, 2, 'atribuicao',    NULL,           NULL, 6, 'Assumiu para atendimento emergencial.',        '2026-08-22 08:10:00'),
  (8, 2, 'mudanca_status','em_andamento', NULL, 6, NULL,                                           '2026-08-22 08:15:00'),
  (9, 2, 'mudanca_status','resolvido',    NULL, 6, 'Buraco tapado e sinalização de segurança removida.', '2026-08-22 17:40:00');

INSERT INTO arquivos (id, id_ticket, path, tipo, created_at) VALUES
  (2, 2, '/uploads/tickets/2/foto_abertura_1.jpg', 'foto_abertura', '2026-08-22 07:03:00');

-- ==========================================================
-- TICKET 3 — MULTI-DEPARTAMENTO: buraco causado por raiz de árvore.
-- Gera solicitação automática para o departamento de Poda,
-- ticket fica "pendente" até a solicitação ser respondida,
-- e o sistema reverte o status sozinho (id_usuario = NULL nesses eventos)
-- ==========================================================

INSERT INTO tickets
  (id, id_usuario, id_categoria, id_departamento, id_funcionario_responsavel, status, prioridade,
   descricao, geom, token_acesso, prazo_primeira_resposta_minutos, prazo_resolucao_minutos, created_at)
VALUES
  (3, 3, 1, 1, 4, 'em_andamento', 'normal',
   'Buraco na Rua das Palmeiras causado por raiz de árvore levantando o asfalto.',
   ST_GeogFromText('SRID=4326;POINT(-47.8390 -24.4790)'),
   NULL, 1440, 5760, -- pergunta2=sim(2880) + pergunta3=sim(1440) => 10080-4320=5760
   '2026-08-18 10:00:00');

INSERT INTO respostas (id, id_pergunta, id_ticket, valor) VALUES
  (9,  1, 3, FALSE),
  (10, 2, 3, TRUE),
  (11, 3, 3, TRUE),
  (12, 4, 3, TRUE); -- raiz de árvore aparente => aciona solicitação p/ Poda (departamento 2)

INSERT INTO ticket_historico (id, id_ticket, tipo_evento, status, prazo_minutos, id_usuario, texto, created_at) VALUES
  (10, 3, 'criacao',       'aberto',        5760, 3,    NULL,                                                   '2026-08-18 10:00:00'),
  (11, 3, 'mudanca_status','em_analise',    NULL, 4,    'Confirmado: raiz de árvore visível no asfalto.',       '2026-08-18 15:00:00'),
  (12, 3, 'mudanca_status','pendente',      NULL, NULL, 'Sistema: aguardando avaliação do departamento de Poda antes de prosseguir.', '2026-08-18 15:01:00'),
  (13, 3, 'mudanca_status','em_analise',    NULL, NULL, 'Sistema: solicitação respondida, retomando o fluxo normal do ticket.',        '2026-08-19 11:30:00'),
  (14, 3, 'atribuicao',    NULL,            NULL, 4,    'Assumiu para reparo do asfalto após liberação da Poda.', '2026-08-19 13:00:00'),
  (15, 3, 'mudanca_status','em_andamento',  NULL, 4,    NULL,                                                    '2026-08-19 13:05:00');

INSERT INTO solicitacoes
  (id, id_ticket, id_departamento_solicitado, status, descricao, resposta, respondido_por, created_at, respondido_em)
VALUES
  (1, 3, 2, 'respondida',
   'Buraco na via aparenta ser causado por raiz de árvore. Podem avaliar se a árvore pode ser podada/removida antes do reparo do asfalto?',
   'Avaliação feita in loco. Raiz pode ser cortada com segurança sem necessidade de remover a árvore. Liberado para reparo da via.',
   5, '2026-08-18 15:05:00', '2026-08-19 11:30:00');

INSERT INTO solicitacao_mensagens (id, id_solicitacao, id_usuario, mensagem, created_at) VALUES
  (1, 1, 4, 'Bom dia, poderiam dar uma olhada nessa raiz assim que possível? Está aumentando o buraco na via.', '2026-08-18 15:10:00'),
  (2, 1, 5, 'Vamos até o local hoje à tarde e retornamos com a avaliação.', '2026-08-18 16:00:00'),
  (3, 1, 5, 'Avaliação concluída, pode prosseguir com o reparo — não é necessário remover a árvore.', '2026-08-19 11:28:00');

INSERT INTO arquivos (id, id_ticket, path, tipo, created_at) VALUES
  (3, 3, '/uploads/tickets/3/foto_abertura_1.jpg', 'foto_abertura', '2026-08-18 10:00:00');

-- exemplo de imagem anexada numa MENSAGEM do chat entre departamentos, não no ticket
INSERT INTO arquivos (id, id_solicitacao_mensagem, path, tipo, created_at) VALUES
  (5, 3, '/uploads/solicitacoes/1/mensagens/3/foto_raiz_avaliada.jpg', 'foto_avaliacao', '2026-08-19 11:28:30');

-- ==========================================================
-- TICKET 4 — Poda de árvore, bloqueia via, gera solicitação para
-- Vias (sinalização) que AINDA está pendente (nenhum funcionário assumiu)
-- ==========================================================

INSERT INTO tickets
  (id, id_usuario, id_categoria, id_departamento, id_funcionario_responsavel, status, prioridade,
   descricao, geom, token_acesso, prazo_primeira_resposta_minutos, prazo_resolucao_minutos, created_at)
VALUES
  (4, 1, 2, 2, NULL, 'pendente', 'normal',
   'Árvore de grande porte caiu parcialmente e está bloqueando a calçada e parte da via na Rua Coronel José Luiz.',
   ST_GeogFromText('SRID=4326;POINT(-47.8420 -24.4860)'),
   'f1e2d3c4b5a647890b1c2d3e4f5a6b7c', 2880, 18720, -- pergunta6=sim(1440) => 20160-1440=18720
   '2026-08-25 06:45:00');

INSERT INTO respostas (id, id_pergunta, id_ticket, valor) VALUES
  (13, 5, 4, FALSE),
  (14, 6, 4, TRUE), -- bloqueia via => aciona solicitação p/ Vias
  (15, 7, 4, TRUE);

INSERT INTO ticket_historico (id, id_ticket, tipo_evento, status, prazo_minutos, id_usuario, texto, created_at) VALUES
  (16, 4, 'criacao',       'aberto',   18720, 1,    NULL,                                                            '2026-08-25 06:45:00'),
  (17, 4, 'mudanca_status','pendente', NULL,  NULL, 'Sistema: aguardando o departamento de Vias sinalizar o local.', '2026-08-25 06:46:00');

INSERT INTO solicitacoes
  (id, id_ticket, id_departamento_solicitado, status, descricao, created_at)
VALUES
  (2, 4, 1, 'pendente',
   'Árvore caída bloqueando parcialmente a via — solicitamos sinalização/isolamento do trecho até a remoção.',
   '2026-08-25 06:46:00');

INSERT INTO arquivos (id, id_ticket, path, tipo, created_at) VALUES
  (4, 4, '/uploads/tickets/4/foto_abertura_1.jpg', 'foto_abertura', '2026-08-25 06:45:00');

-- ==========================================================
-- TICKET 5 — Bueiro entupido, fechado por duplicidade
-- (ilustra o status "fechado" sem execução do serviço)
-- ==========================================================

INSERT INTO tickets
  (id, id_usuario, id_categoria, id_departamento, id_funcionario_responsavel, status, prioridade,
   descricao, geom, token_acesso, prazo_primeira_resposta_minutos, prazo_resolucao_minutos, created_at)
VALUES
  (5, 2, 3, 3, 7, 'fechado', 'normal',
   'Bueiro entupido na esquina da Rua Barão do Rio Branco com Rua Cel. Joaquim.',
   ST_GeogFromText('SRID=4326;POINT(-47.8470 -24.4845)'),
   NULL, 720, 4320,
   '2026-08-19 16:20:00');

INSERT INTO respostas (id, id_pergunta, id_ticket, valor) VALUES
  (16, 8, 5, FALSE),
  (17, 9, 5, FALSE);

INSERT INTO ticket_historico (id, id_ticket, tipo_evento, status, prazo_minutos, id_usuario, texto, created_at) VALUES
  (18, 5, 'criacao',       'aberto',  4320, 2, NULL,                                                              '2026-08-19 16:20:00'),
  (19, 5, 'atribuicao',    NULL,      NULL, 7, 'Assumiu para verificação.',                                       '2026-08-19 18:00:00'),
  (20, 5, 'mudanca_status','fechado', NULL, 7, 'Chamado duplicado — já existe o ticket #6 aberto para o mesmo bueiro.', '2026-08-19 18:10:00');

-- ---------- NOTIFICAÇÕES (exemplos) ----------

-- novo_ticket: todos os funcionários do departamento de Vias (ticket 1)
INSERT INTO notificacoes (id, id_usuario, tipo_evento, id_ticket, canal, status, created_at, enviado_em) VALUES
  (1, 4, 'novo_ticket', 1, 'push', 'enviada', '2026-08-20 09:12:00', '2026-08-20 09:12:05'),
  (2, 6, 'novo_ticket', 1, 'push', 'enviada', '2026-08-20 09:12:00', '2026-08-20 09:12:05');

-- nova_solicitacao: todos os funcionários do departamento de Poda (ticket 3 -> solicitacao 1)
INSERT INTO notificacoes (id, id_usuario, tipo_evento, id_ticket, id_solicitacao, canal, status, created_at, enviado_em) VALUES
  (3, 5, 'nova_solicitacao', 3, 1, 'push', 'enviada', '2026-08-18 15:01:00', '2026-08-18 15:01:04');

-- solicitacao_respondida: ticket 3 já tinha funcionário responsável (Carlos) quando foi criado? Não, só depois.
-- Nesse caso ninguém era responsável ainda -> notifica todo o departamento dono do ticket (Vias)
INSERT INTO notificacoes (id, id_usuario, tipo_evento, id_ticket, id_solicitacao, canal, status, created_at, enviado_em) VALUES
  (4, 4, 'solicitacao_respondida', 3, 1, 'push', 'enviada', '2026-08-19 11:30:00', '2026-08-19 11:30:03'),
  (5, 6, 'solicitacao_respondida', 3, 1, 'push', 'lida',    '2026-08-19 11:30:00', '2026-08-19 11:30:03');

-- notificação ainda não processada pelo worker (exemplo de fila pendente)
INSERT INTO notificacoes (id, id_usuario, tipo_evento, id_ticket, id_solicitacao, canal, status, created_at) VALUES
  (6, 4, 'nova_solicitacao', 4, 2, 'push', 'pendente', '2026-08-25 06:46:00');

-- ---------- LOGS DE AUDITORIA (exemplos) ----------

INSERT INTO logs_auditoria (id, id_usuario, acao, entidade_tipo, entidade_id, dados_antigos, dados_novos, created_at) VALUES
  (1, NULL, 'categoria_alterada', 'categorias', 1,
     '{"tempo_maximo_resolucao_minutos": 7200}'::jsonb,
     '{"tempo_maximo_resolucao_minutos": 10080}'::jsonb,
     '2026-08-10 10:00:00'),
  (2, 6, 'tipo_usuario_alterado', 'usuarios', 6,
     '{"tipo_usuario": "municipe"}'::jsonb,
     '{"tipo_usuario": "funcionario"}'::jsonb,
     '2026-07-15 09:00:00');

-- ==========================================================
-- FIM DO SCRIPT
-- ==========================================================
