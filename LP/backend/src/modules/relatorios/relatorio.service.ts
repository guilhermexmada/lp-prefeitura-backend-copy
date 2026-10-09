import { Prisma, TicketStatus } from '@prisma/client';
import { prisma } from '../../shared/database/prisma.js';
import { AppError } from '../../shared/errors/app-error.js';
import { validarPeriodo, type Periodo } from '../../shared/utils/periodo.js';
import { PeriodoQueryDTO, PorCategoriaQueryDTO } from './dtos/relatorio.dto.js';

// formato para retorno cru do postgres
interface ConsultaTemposDeTicket {
    media_resolucao_minutos: Prisma.Decimal | null;
    media_primeira_resposta_minutos: Prisma.Decimal | null;
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
            this.totalOcorrencias(periodo),
            this.totalOcorrencias(periodo.anterior),
        ]);

        // taxa de resolução
        const [resolucaoAtual, resolucaoAnterior] = await Promise.all([
            this.taxaResolucao(periodo),
            this.taxaResolucao(periodo.anterior)
        ]);

        const [tempoAtual, tempoAnterior] = await Promise.all([

        ])

        return {
            ticketsTotais: totalAtual,
            ticketsTotaisPeriodoAnterior: totalAnterior,
            taxaResolucaoAtual: resolucaoAtual,
            taxaResolucaoAnterior: resolucaoAnterior,
        }
    }

    // conta total de tickets em um período e departamento
    async totalOcorrencias(periodo: Periodo, departamentoId?: number): Promise<number> {
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
        const [tempos] = await prisma.$queryRaw<ConsultaTemposDeTicket[]>`
            WITH tickets_periodo AS (
      SELECT t.id, t.created_at
      FROM tickets t
      WHERE t.created_at >= ${periodo.inicio}::timestamp
        AND t.created_at <  ${periodo.fim}::timestamp
        AND t.status <> 'fechado'
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

    async getVolumeChamados() { }
    async getOcorrenciasPorCategoria() { }
    async getDesempenhoPorDepartamento() { }
}

export const relatorioService = new RelatorioService();