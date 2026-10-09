import { AppError } from '../errors/app-error.js'; // ajuste o caminho

const DIA_MS = 86_400_000;
const PERIODO_PADRAO_DIAS = 30;
const PERIODO_MAXIMO_DIAS = 366;

export interface Periodo {
  inicio: Date;
  fim: Date;
}

export interface PeriodoComparativo extends Periodo {
  anterior: Periodo;
}

export function validarPeriodo(inicio?: Date, fim?: Date): PeriodoComparativo {
  const hoje = new Date()

  const fimEfetivo = fim ? fim : hoje;
  const inicioEfetivo = inicio ? inicio : new Date(fimEfetivo.getTime() - PERIODO_PADRAO_DIAS);

  if (inicioEfetivo >= fimEfetivo) {
    throw new AppError('A data inicial deve ser anterior ou igual à data final', 400);
  }

  const duracao = fimEfetivo.getTime() - inicioEfetivo.getTime();

  if (duracao > PERIODO_MAXIMO_DIAS * DIA_MS) {
    throw new AppError(`O período não pode passar de ${PERIODO_MAXIMO_DIAS} dias`, 400);
  }

  return {
    inicio: inicioEfetivo,
    fim: fimEfetivo,
    anterior: {
      inicio: new Date(inicioEfetivo.getTime() - duracao),
      fim: inicioEfetivo,
    },
  };
}