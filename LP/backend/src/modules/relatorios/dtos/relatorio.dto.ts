import z from 'zod';
import { periodoQuerySchema } from "../schemas/relatorio.schema.js";

export type PeriodoQueryDTO = z.infer<typeof periodoQuerySchema>;