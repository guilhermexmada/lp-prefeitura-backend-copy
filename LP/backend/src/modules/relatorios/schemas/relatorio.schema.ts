// modules/relatorios/schemas/relatorio.schema.ts
import { z } from 'zod';

const DIAS_MAXIMOS = 366;
const UM_DIA_MS = 24 * 60 * 60 * 1000;

const dataSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Use o formato AAAA-MM-DD')
  .refine((valor) => {
    const data = new Date(valor);
    // Rejeita datas inexistentes, como 2026-02-31, que o JS "corrigiria" para março
    return !isNaN(data.getTime()) && data.toISOString().startsWith(valor);
  }, 'Data inválida');

export const periodoQuerySchema = z
  .object({
    inicio: dataSchema,
    fim: dataSchema, // exclusivo: para agosto inteiro, fim = 2026-09-01
    departamentoId: z.coerce.number().int().positive().optional(),
  })
  .refine((query) => query.inicio < query.fim, {
    message: 'A data final deve ser posterior à data inicial',
    path: ['fim'],
  })
  .refine(
    (query) => (new Date(query.fim).getTime() - new Date(query.inicio).getTime()) / UM_DIA_MS <= DIAS_MAXIMOS,
    { message: `O período não pode passar de ${DIAS_MAXIMOS} dias`, path: ['fim'] },
  );