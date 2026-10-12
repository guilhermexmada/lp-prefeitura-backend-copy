import { z } from 'zod';
import { mapaTicketsQuerySchema } from '../schemas/mapa.schema.js';

export type MapaTicketsQueryDTO = z.infer<typeof mapaTicketsQuerySchema>;