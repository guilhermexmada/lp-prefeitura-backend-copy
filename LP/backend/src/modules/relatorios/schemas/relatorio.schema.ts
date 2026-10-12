// modules/relatorios/schemas/relatorio.schema.ts
import { z } from 'zod';
import { dataSchema, diasEntre, DIAS_MAXIMOS } from '../../../shared/schemas/data.schema.js';

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
    (query) => (diasEntre(query.inicio, query.fim) <= DIAS_MAXIMOS),
    { message: `O período não pode passar de ${DIAS_MAXIMOS} dias`, path: ['fim'] },
  );