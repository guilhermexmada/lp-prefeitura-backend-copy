// modules/dashboard/schemas/mapa.schema.ts
import { TicketStatus } from '@prisma/client';
import { z } from 'zod';
import { dataSchema, diasEntre, DIAS_MAXIMOS } from '../../../shared/schemas/data.schema.js';

const LIMITE_PADRAO = 500;
const LIMITE_MAXIMO = 2000;
const RAIO_MAXIMO_KM = 50;

// Sem isso, '?lat=' vira 0 no z.coerce.number, que é uma coordenada válida no oceano
const vazioParaUndefined = (valor: unknown) =>
    typeof valor === 'string' && valor.trim() === '' ? undefined : valor;

// Aceita ?status=aberto,pendente e ?status=aberto&status=pendente
const listaDaQuery = (valor: unknown) => {
    if (valor === undefined || valor === '') return undefined;
    const itens = Array.isArray(valor) ? valor : [valor];
    return itens
        .flatMap((item) => String(item).split(','))
        .map((item) => item.trim())
        .filter(Boolean);
};

export const mapaTicketsQuerySchema = z
    .object({
        inicio: dataSchema.optional(),
        fim: dataSchema.optional(), // exclusivo, como nos relatórios
        status: z.preprocess(listaDaQuery, z.array(z.nativeEnum(TicketStatus)).optional()),
        departamentoId: z.preprocess(vazioParaUndefined, z.coerce.number().int().positive().optional()),
        busca: z.preprocess(
            vazioParaUndefined,
            z.string().trim().min(2, 'A busca precisa de ao menos 2 caracteres').max(100).optional(),
        ),
        lat: z.preprocess(vazioParaUndefined, z.coerce.number().min(-90).max(90).optional()),
        lng: z.preprocess(vazioParaUndefined, z.coerce.number().min(-180).max(180).optional()),
        raioKm: z.preprocess(vazioParaUndefined, z.coerce.number().positive().max(RAIO_MAXIMO_KM).optional()),
        limite: z.preprocess(
            vazioParaUndefined,
            z.coerce.number().int().positive().max(LIMITE_MAXIMO).default(LIMITE_PADRAO),
        ),
    })
    .refine((q) => (q.inicio === undefined) === (q.fim === undefined), {
        message: 'Informe inicio e fim juntos',
        path: ['fim'],
    })
    .refine((q) => !q.inicio || !q.fim || q.inicio < q.fim, {
        message: 'A data final deve ser posterior à data inicial',
        path: ['fim'],
    })
    .refine((q) => !q.inicio || !q.fim || diasEntre(q.inicio, q.fim) <= DIAS_MAXIMOS, {
        message: `O período não pode passar de ${DIAS_MAXIMOS} dias`,
        path: ['fim'],
    })
    .refine((q) => (q.lat === undefined) === (q.lng === undefined), {
        message: 'Informe lat e lng juntos',
        path: ['lng'],
    })
    .refine((q) => q.raioKm === undefined || q.lat !== undefined, {
        message: 'raioKm exige lat e lng',
        path: ['raioKm'],
    });