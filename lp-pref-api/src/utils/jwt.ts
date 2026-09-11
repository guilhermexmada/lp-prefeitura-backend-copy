import jwt, { type SignOptions } from 'jsonwebtoken';
import type { tipo_usuario_enum } from '../generated/prisma/client.js';

const expiresIn = (process.env.JWT_EXPIRES_IN || '7d') as SignOptions['expiresIn'];

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  throw new Error('JWT_SECRET não definido no .env');
}

export interface TokenPayload {
  id: number;
  tipo_usuario: tipo_usuario_enum;
}

export function generateToken(payload: TokenPayload): string {
  if (!JWT_SECRET) {
    throw new Error('JWT_SECRET não definido no .env');
  }

  return jwt.sign(payload, JWT_SECRET, {
    expiresIn: expiresIn || '7d',
  });
}

export function verifyToken(token: string): TokenPayload {
  if (!JWT_SECRET) {
    throw new Error('JWT_SECRET não definido no .env');
  }

  return jwt.verify(token, JWT_SECRET) as TokenPayload;
}
