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

function hojeEmBrasilia(): string {
  // 'en-CA' formata como AAAA-MM-DD
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Sao_Paulo' }).format(new Date());
}

function somarDias(data: string, dias: number): string {
  const d = new Date(`${data}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + dias);
  return d.toISOString().slice(0, 10);
}

// fim exclusivo = amanhã, para incluir o dia de hoje
export function periodoUltimosDias(dias: number): { inicio: string; fim: string } {
  const fim = somarDias(hojeEmBrasilia(), 1);
  return { inicio: somarDias(fim, -dias), fim };
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