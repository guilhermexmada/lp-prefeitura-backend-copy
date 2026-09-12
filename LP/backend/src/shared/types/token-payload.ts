import { TipoUsuario } from '@prisma/client';

export interface TokenPayload {
  id: number
  email: string | null // nulo para usuários anônimos
  tipoUsuario: TipoUsuario
}