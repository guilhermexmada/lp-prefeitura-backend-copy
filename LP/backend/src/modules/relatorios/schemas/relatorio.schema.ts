import { z } from 'zod';

export const periodoQuerySchema = z
    .object({
        inicio: z.coerce.date().optional(),
        fim: z.coerce.date().optional(),
        departamentoId: z.coerce.number().int().positive().optional(),
    })
    .strict();

export const porCategoriaQuerySchema = periodoQuerySchema.extend({
    agruparPor: z.enum(['categoria', 'departamento']).default('categoria'),
});