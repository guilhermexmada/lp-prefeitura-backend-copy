import { Prisma, TicketStatus } from '@prisma/client';
import { prisma } from '../../shared/database/prisma.js';
import { montarPeriodo, type Periodo } from '../../shared/utils/periodo.js';
import { decimalParaMinutos } from '../../shared/utils/units.js';
import { PeriodoQueryDTO } from './dtos/relatorio.dto.js';
import type {
    ConsultaDesempenhoDepartamento,
    ConsultaTemposMedios,
    ConsultaVolumeSemanal,
    DesempenhoDepartamento,
} from './types/relatorio.types.js';
import { classificarDesempenho } from './rules/relatorio.rules.js';

class RelatorioService {
    async getIndicadores(query: PeriodoQueryDTO) {
        const { inicio, fim, departamentoId } = query;
        const periodo = montarPeriodo(inicio, fim);

        const [totalAtual, resolucaoAtual, tempoAtual,
        ] = await Promise.all([
            this.contarTicketsTotais(periodo, departamentoId),
            this.contarTicketsResolvidos(periodo, departamentoId),
            this.calcularTemposMediosTicket(periodo, departamentoId),
        ])

        return {
            ticketsTotais: totalAtual,
            ticketsResolvidos: resolucaoAtual,
            temposTicket: tempoAtual,
        }
    }

    async getVolumeSemanal(query: PeriodoQueryDTO) {
        const { inicio, fim, departamentoId } = query;
        const periodo = montarPeriodo(inicio, fim);

        const volumeSemanal = await this.calcularVolumeTickets(periodo, departamentoId);

        return volumeSemanal;
    }

    async getTicketsPorCategoria(query: PeriodoQueryDTO) {
        const { inicio, fim, departamentoId } = query;
        const periodo = montarPeriodo(inicio, fim);

        const ticketsCategoria = await this.contarTicketsPorCategoria(periodo, departamentoId);

        return ticketsCategoria;
    }

    async getDesempenhoPorDepartamento(query: PeriodoQueryDTO) {
        const { inicio, fim } = query;
        const periodo = montarPeriodo(inicio, fim);

        const desempenhoDepartamento = await this.calcularDesempenhoPorDepartamento(periodo);

        return desempenhoDepartamento;
    }

    private async contarTicketsTotais(periodo: Periodo, departamentoId?: number): Promise<number> {
        const where: Prisma.TicketWhereInput = {
            createdAt: { gte: periodo.inicio, lt: periodo.fim },
            idDepartamento: departamentoId,
            status: { not: TicketStatus.fechado }
        }

        const totalTickets = await prisma.ticket.count({ where });

        return totalTickets;
    }

    private async contarTicketsResolvidos(periodo: Periodo, departamentoId?: number): Promise<number> {
        const where: Prisma.TicketWhereInput = {
            createdAt: { gte: periodo.inicio, lt: periodo.fim },
            idDepartamento: departamentoId,
            status: TicketStatus.resolvido
        }

        const resolvidos = await prisma.ticket.count({ where });

        return resolvidos;
    }

    private async calcularTemposMediosTicket(periodo: Periodo, departamentoId?: number) {
        const filtroDepartamento =
            departamentoId !== undefined
                ? Prisma.sql`AND t.id_departamento = ${departamentoId}`
                : Prisma.empty;

        const [tempos] = await prisma.$queryRaw<ConsultaTemposMedios[]>`
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

    private async calcularVolumeTickets(periodo: Periodo, departamentoId?: number) {
        const filtroDepartamento =
            departamentoId !== undefined
                ? Prisma.sql`AND t.id_departamento = ${departamentoId}`
                : Prisma.empty;

        const volume = await prisma.$queryRaw<ConsultaVolumeSemanal[]>`
            WITH semanas AS (
      -- Todas as segundas-feiras do período, mesmo sem tickets
      SELECT generate_series(
    date_trunc('week', ${periodo.inicio}::timestamptz AT TIME ZONE 'America/Sao_Paulo'),
    date_trunc('week', (${periodo.fim}::timestamptz - interval '1 microsecond') AT TIME ZONE 'America/Sao_Paulo'),
    interval '1 week'
  ) AS semana
    ),
    abertos AS (
  SELECT date_trunc('week', t.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo') AS semana,
         COUNT(*) AS total
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
  SELECT date_trunc('week', r.resolvido_em AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo') AS semana,
         COUNT(*) AS total
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

    private async contarTicketsPorCategoria(periodo: Periodo, departamentoId?: number) {
        const where = {
            createdAt: { gte: periodo.inicio, lt: periodo.fim },
            idDepartamento: departamentoId,
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

        return {
            categorias: grupos.map((grupo) => ({
                idCategoria: grupo.idCategoria,
                nome: nomePorId.get(grupo.idCategoria) ?? 'Categoria desconhecida',
                quantidade: grupo._count._all,
            })),
        }
    }

    private async calcularDesempenhoPorDepartamento(
        periodo: Periodo,
        departamentoId?: number,
    ): Promise<DesempenhoDepartamento[]> {
        const filtroDepartamento =
            departamentoId !== undefined
                ? Prisma.sql`AND d.id = ${departamentoId}`
                : Prisma.empty;

        const linhas = await prisma.$queryRaw<ConsultaDesempenhoDepartamento[]>`
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
                    COUNT(*)                                        AS tickets_totais,
                    COUNT(*) FILTER (WHERE tp.status = 'resolvido') AS tickets_resolvidos,
                    AVG(EXTRACT(EPOCH FROM (r.resolvido_em - tp.created_at)) / 60) AS media_resolucao_minutos,
                    COUNT(*) FILTER (
                        WHERE tp.status = 'resolvido'
                          AND r.resolvido_em - tp.created_at <= make_interval(mins => tp.prazo_resolucao_minutos)
                    )                                               AS resolvidos_no_prazo
                FROM tickets_periodo tp
                LEFT JOIN resolucao r ON r.id_ticket = tp.id
                GROUP BY tp.id_departamento
            )
            SELECT
                d.id                                AS id_departamento,
                d.nome                              AS departamento,
                s.nome                              AS secretaria,
                COALESCE(m.tickets_totais, 0)       AS tickets_totais,
                COALESCE(m.tickets_resolvidos, 0)   AS tickets_resolvidos,
                m.media_resolucao_minutos,
                COALESCE(m.resolvidos_no_prazo, 0)  AS resolvidos_no_prazo
            FROM departamentos d
            JOIN secretarias s ON s.id = d.id_secretaria
            LEFT JOIN metricas m ON m.id_departamento = d.id
            WHERE d.ativo = true
              ${filtroDepartamento}
            ORDER BY tickets_totais DESC, d.nome
        `;

        return linhas.map((linha) => {
            const ticketsResolvidos = Number(linha.tickets_resolvidos);
            const resolvidosNoPrazo = Number(linha.resolvidos_no_prazo);

            return {
                idDepartamento: linha.id_departamento,
                departamento: linha.departamento,
                secretaria: linha.secretaria,
                ticketsTotais: Number(linha.tickets_totais),
                ticketsResolvidos,
                tempoMedioResolucaoMinutos: decimalParaMinutos(linha.media_resolucao_minutos),
                resolvidosNoPrazo,
                statusGeral: classificarDesempenho(resolvidosNoPrazo, ticketsResolvidos),
            };
        });
    }
}

export const relatorioService = new RelatorioService();