export interface Periodo {
  inicio: Date; // inclusivo, instante em UTC
  fim: Date;    // exclusivo, instante em UTC
}

export interface PeriodoComAnterior extends Periodo {
  anterior: Periodo;
}

// O Brasil não tem horário de verão desde 2019, então o deslocamento é fixo
const OFFSET_BRASILIA = '-03:00';

// '2026-08-01' -> meia-noite em Brasília -> 2026-08-01T03:00:00.000Z
function meiaNoiteEmBrasilia(data: string): Date {
  return new Date(`${data}T00:00:00${OFFSET_BRASILIA}`);
}

export function montarPeriodo(inicio: string, fim: string): PeriodoComAnterior {
  const inicioUtc = meiaNoiteEmBrasilia(inicio);
  const fimUtc = meiaNoiteEmBrasilia(fim);
  const duracaoMs = fimUtc.getTime() - inicioUtc.getTime();

  return {
    inicio: inicioUtc,
    fim: fimUtc,
    anterior: { inicio: new Date(inicioUtc.getTime() - duracaoMs), fim: inicioUtc },
  };
}