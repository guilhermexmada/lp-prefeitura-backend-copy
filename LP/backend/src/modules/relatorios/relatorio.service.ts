import { Prisma, TicketStatus } from '@prisma/client';
import { prisma } from '../../shared/database/prisma.js';
import { AppError } from '../../shared/errors/app-error.js';
import { validarPeriodo, type Periodo } from '../../shared/utils/periodo.js';
import { PeriodoQueryDTO, PorCategoriaQueryDTO } from './dtos/relatorio.dto.js';

interface ConsultaTemposDeTicket {
    media_resolucao_minutos: Prisma.Decimal | null;
    media_primeira_resposta_minutos: Prisma.Decimal | null;
}

interface ConsultaVolumeSemanal {
    semana_inicio: string; // 'YYYY-MM-DD'
    abertos: bigint;
    concluidos: bigint;
}

interface ConsultaDesempenhoDepartamento {
    id_departamento: number;
    departamento: string;
    secretaria: string;
    total: bigint;
    concluidos: bigint;
    media_resolucao_minutos: Prisma.Decimal | null;
    total_com_resolucao: bigint;
    resolvidos_no_prazo: bigint;
}

type StatusGeral = 'Excelente' | 'Bom' | 'Regular' | 'Crítico' | 'Sem dados';

// Regra de negócio: faixas pelo % de tickets resolvidos dentro do prazo.
// Os valores devem ser combinados com o PO.
const FAIXAS_STATUS: { minimo: number; status: StatusGeral }[] = [
    { minimo: 90, status: 'Excelente' },
    { minimo: 70, status: 'Bom' },
    { minimo: 50, status: 'Regular' },
];

function classificarStatus(percentualNoPrazo: number | null): StatusGeral {
    if (percentualNoPrazo === null) return 'Sem dados';
    const faixa = FAIXAS_STATUS.find((f) => percentualNoPrazo >= f.minimo);
    return faixa?.status ?? 'Crítico';
}

function decimalParaMinutos(valor: Prisma.Decimal | null): number | null {
    return valor === null ? null : Math.round(Number(valor));
}

class RelatorioService {
    // 4 cards
    async getIndicadores(query: PeriodoQueryDTO) {
        // total de tickets
        const periodo = validarPeriodo(query.inicio, query.fim);

        const [totalAtual, totalAnterior] = await Promise.all([
            this.totalTickets(periodo),
            this.totalTickets(periodo.anterior),
        ]);

        // taxa de resolução
        const [resolucaoAtual, resolucaoAnterior] = await Promise.all([
            this.taxaResolucao(periodo),
            this.taxaResolucao(periodo.anterior)
        ]);

        // tempos de ticket
        const [tempoAtual, tempoAnterior] = await Promise.all([
            this.temposTicket(periodo),
            this.temposTicket(periodo.anterior)
        ])

        const variacaoResolucao = tempoAtual.resolucaoMinutos === null || tempoAnterior.resolucaoMinutos === null
            ? null
            : tempoAtual.resolucaoMinutos - tempoAnterior.resolucaoMinutos;

        // volume semanal de tickets
        const volumeSemanal = await this.volumeChamados(periodo);

        // tickets por categoria
        const ticketsCategoria = await this.ticketsPorCategoria(periodo);

        // desempenho por departamento
        const desempenhoDepartamento = await this.desempenhoPorDepartamento(periodo);

        return {
            tickets_totais: totalAtual,
            tickets_totais_anterior: totalAnterior,
            taxa_resolucao: resolucaoAtual,
            taxa_resolucao_anterior: resolucaoAnterior,
            tempos_ticket: tempoAtual,
            tempos_ticket_anterior: tempoAnterior,
            variacao_resolucao_minutos: variacaoResolucao,
            volume_ticket_semanal: volumeSemanal,
            tickets_por_categoria: ticketsCategoria,
            desempenho_por_departamento: desempenhoDepartamento
        }
    }

    // conta total de tickets em um período e departamento
    async totalTickets(periodo: Periodo, departamentoId?: number): Promise<number> {
        const where: Prisma.TicketWhereInput = {
            createdAt: { gte: periodo.inicio, lt: periodo.fim },
            idDepartamento: departamentoId ? departamentoId : undefined
        }

        const totalTickets = await prisma.ticket.count({ where });

        return totalTickets;
    }

    // calcula taxa de resolução dos tickets em um período e departamento
    async taxaResolucao(periodo: Periodo, departamentoId?: number): Promise<number | null> {
        const where: Prisma.TicketWhereInput = {
            createdAt: { gte: periodo.inicio, lt: periodo.fim },
            idDepartamento: departamentoId ? departamentoId : undefined,
            status: { not: TicketStatus.fechado } // fechados não entram no total
        }

        const [total, resolvidos] = await Promise.all([
            prisma.ticket.count({ where: where }),
            prisma.ticket.count({ where: { ...where, status: TicketStatus.resolvido } })
        ])

        const taxa = total === 0 ? null : Number((resolvidos / total) * 100);

        return taxa;
    }

    async temposTicket(periodo: Periodo, departamentoId?: number) {
        const filtroDepartamento =
            departamentoId !== undefined
                ? Prisma.sql`AND t.id_departamento = ${departamentoId}`
                : Prisma.empty;

        const [tempos] = await prisma.$queryRaw<ConsultaTemposDeTicket[]>`
            WITH tickets_periodo AS (
      SELECT t.id, t.created_at
      FROM tickets t
      WHERE t.created_at >= ${periodo.inicio}::timestamp
        AND t.created_at <  ${periodo.fim}::timestamp
        AND t.status <> 'fechado'
        ${filtroDepartamento}
    ),
    primeira_resposta AS (
      SELECT h.id_ticket, MIN(h.created_at) AS respondido_em
      FROM ticket_historico h
      JOIN usuarios u ON u.id = h.id_usuario
      WHERE h.tipo_evento <> 'criacao'
        AND u.tipo_usuario IN ('funcionario', 'gestor')
      GROUP BY h.id_ticket
    ),
    resolucao AS (
      SELECT h.id_ticket, MIN(h.created_at) AS resolvido_em
      FROM ticket_historico h
      WHERE h.tipo_evento = 'mudanca_status'
        AND h.status = 'resolvido'
      GROUP BY h.id_ticket
    )
    SELECT
      AVG(EXTRACT(EPOCH FROM (r.resolvido_em - tp.created_at)) / 60)    AS media_resolucao_minutos,
      AVG(EXTRACT(EPOCH FROM (pr.respondido_em - tp.created_at)) / 60)  AS media_primeira_resposta_minutos
    FROM tickets_periodo tp
    LEFT JOIN primeira_resposta pr ON pr.id_ticket = tp.id
    LEFT JOIN resolucao r ON r.id_ticket = tp.id
        `;

        return {
            resolucaoMinutos: decimalParaMinutos(tempos.media_resolucao_minutos),
            primeiraRespostaMinutos: decimalParaMinutos(tempos.media_primeira_resposta_minutos)
        }
    }

    async volumeChamados(periodo: Periodo, departamentoId?: number) {
        const filtroDepartamento =
            departamentoId !== undefined
                ? Prisma.sql`AND t.id_departamento = ${departamentoId}`
                : Prisma.empty;

        const volume = await prisma.$queryRaw<ConsultaVolumeSemanal[]>`
            WITH semanas AS (
      -- Todas as segundas-feiras do período, mesmo sem tickets
      SELECT generate_series(
        date_trunc('week', ${periodo.inicio}::timestamp),
        date_trunc('week', ${periodo.fim}::timestamp - interval '1 microsecond'),
        interval '1 week'
      ) AS semana
    ),
    abertos AS (
      SELECT date_trunc('week', t.created_at) AS semana, COUNT(*) AS total
      FROM tickets t
      WHERE t.created_at >= ${periodo.inicio}::timestamp
        AND t.created_at <  ${periodo.fim}::timestamp
        AND t.status <> 'fechado'
        ${filtroDepartamento}
      GROUP BY 1
    ),
    resolucao AS (
      SELECT h.id_ticket, MIN(h.created_at) AS resolvido_em
      FROM ticket_historico h
      WHERE h.tipo_evento = 'mudanca_status'
        AND h.status = 'resolvido'
      GROUP BY h.id_ticket
    ),
    concluidos AS (
      SELECT date_trunc('week', r.resolvido_em) AS semana, COUNT(*) AS total
      FROM resolucao r
      JOIN tickets t ON t.id = r.id_ticket
      WHERE r.resolvido_em >= ${periodo.inicio}::timestamp
        AND r.resolvido_em <  ${periodo.fim}::timestamp
        ${filtroDepartamento}
      GROUP BY 1
    )
    SELECT
      to_char(s.semana, 'YYYY-MM-DD') AS semana_inicio,
      COALESCE(a.total, 0)            AS abertos,
      COALESCE(c.total, 0)            AS concluidos
    FROM semanas s
    LEFT JOIN abertos a    ON a.semana = s.semana
    LEFT JOIN concluidos c ON c.semana = s.semana
    ORDER BY s.semana
        `;
        return volume.map((linha) => ({
            semanaInicio: linha.semana_inicio,
            abertos: Number(linha.abertos),
            concluidos: Number(linha.concluidos)
        }));
    }
    async ticketsPorCategoria(periodo: Periodo) {
        const where = {
            createdAt: { gte: periodo.inicio, lt: periodo.fim },
            status: { not: TicketStatus.fechado }
        }

        const grupos = await prisma.ticket.groupBy({
            by: ['idCategoria'],
            where,
            _count: { _all: true },
            orderBy: { _count: { idCategoria: 'desc' } }
        });

        const categorias = await prisma.categoria.findMany({
            where: { id: { in: grupos.map((grupo) => grupo.idCategoria) } },
            select: { id: true, nome: true },
        });

        const nomePorId = new Map(categorias.map((categoria) => [categoria.id, categoria.nome]));

        const total = grupos.reduce((soma, grupo) => soma + grupo._count._all, 0);

        return {
            total,
            categorias: grupos.map((grupo) => ({
                idCategoria: grupo.idCategoria,
                nome: nomePorId.get(grupo.idCategoria) ?? 'Categoria desconhecida',
                quantidade: grupo._count._all,
                percentual: Number(((grupo._count._all / total) * 100).toFixed(1)),
            })),
        }
    }

    async desempenhoPorDepartamento(periodo: Periodo) {
        const desempenhos = await prisma.$queryRaw<ConsultaDesempenhoDepartamento[]>`
    WITH tickets_periodo AS (
      SELECT t.id, t.id_departamento, t.status, t.created_at, t.prazo_resolucao_minutos
      FROM tickets t
      WHERE t.created_at >= ${periodo.inicio}::timestamp
        AND t.created_at <  ${periodo.fim}::timestamp
        AND t.status <> 'fechado'
    ),
    resolucao AS (
      SELECT h.id_ticket, MIN(h.created_at) AS resolvido_em
      FROM ticket_historico h
      WHERE h.tipo_evento = 'mudanca_status'
        AND h.status = 'resolvido'
      GROUP BY h.id_ticket
    ),
    metricas AS (
      SELECT
        tp.id_departamento,
        COUNT(*)                                          AS total,
        COUNT(*) FILTER (WHERE tp.status = 'resolvido')   AS concluidos,
        AVG(EXTRACT(EPOCH FROM (r.resolvido_em - tp.created_at)) / 60) AS media_resolucao_minutos,
        COUNT(r.id_ticket)                                AS total_com_resolucao,
        COUNT(*) FILTER (
          WHERE r.resolvido_em - tp.created_at <= make_interval(mins => tp.prazo_resolucao_minutos)
        )                                                 AS resolvidos_no_prazo
      FROM tickets_periodo tp
      LEFT JOIN resolucao r ON r.id_ticket = tp.id
      GROUP BY tp.id_departamento
    )
    SELECT
      d.id                                 AS id_departamento,
      d.nome                               AS departamento,
      s.nome                               AS secretaria,
      COALESCE(m.total, 0)                 AS total,
      COALESCE(m.concluidos, 0)            AS concluidos,
      m.media_resolucao_minutos,
      COALESCE(m.total_com_resolucao, 0)   AS total_com_resolucao,
      COALESCE(m.resolvidos_no_prazo, 0)   AS resolvidos_no_prazo
    FROM departamentos d
    JOIN secretarias s ON s.id = d.id_secretaria
    LEFT JOIN metricas m ON m.id_departamento = d.id
    WHERE d.ativo = true
    ORDER BY total DESC, d.nome
  `;

        return desempenhos.map((linha) => {
            const totalComResolucao = Number(linha.total_com_resolucao);
            const percentualNoPrazo =
                totalComResolucao === 0
                    ? null
                    : Number(((Number(linha.resolvidos_no_prazo) / totalComResolucao) * 100).toFixed(1));
            return {
                idDepartamento: linha.id_departamento,
                departamento: linha.departamento,
                secretaria: linha.secretaria,
                chamadosTotais: Number(linha.total),
                concluidos: Number(linha.concluidos),
                tempoMedioSolucaoMinutos:
                    linha.media_resolucao_minutos === null
                        ? null
                        : Math.round(Number(linha.media_resolucao_minutos)),
                percentualNoPrazo,
                statusGeral: classificarStatus(percentualNoPrazo),
            };
        });
    }
}

export const relatorioService = new RelatorioService();