import { z } from 'zod';

export const DIAS_MAXIMOS = 366;
export const UM_DIA_MS = 24 * 60 * 60 * 1000;

export const dataSchema = z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Use o formato AAAA-MM-DD')
    .refine((valor) => {
        const data = new Date(valor);
        // Rejeita datas inexistentes, como 2026-02-31, que o JS "corrigiria" para março
        return !isNaN(data.getTime()) && data.toISOString().startsWith(valor);
    }, 'Data inválida');

export function diasEntre(inicio: string, fim: string): number {
    return (new Date(fim).getTime() - new Date(inicio).getTime()) / UM_DIA_MS;
}