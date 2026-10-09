import z from 'zod';
import { periodoQuerySchema, porCategoriaQuerySchema } from "../schemas/relatorio.schema.js";

export type PeriodoQueryDTO = z.infer<typeof periodoQuerySchema>;
export type PorCategoriaQueryDTO = z.infer<typeof porCategoriaQuerySchema>;