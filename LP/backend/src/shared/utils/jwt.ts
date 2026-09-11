import jwt, { type SignOptions } from "jsonwebtoken";
import type { TipoUsuario } from "@prisma/client";

// valida que o secret não é undefined
function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error("JWT_SECRET não definido no .env");
  }
  return secret;
}

const JWT_SECRET = getJwtSecret();

// valida tipo do tempo de expiração
const expiresIn = (process.env.JWT_EXPIRES_IN ?? "7d") as SignOptions["expiresIn"];

// molde para credenciais de token
export interface TokenPayload {
  id: number;
  tipo_usuario: TipoUsuario;
}

// valida formato das credenciais
function isTokenPayload(payload: unknown): payload is TokenPayload {
  return (
    typeof payload === "object" &&
    payload !== null &&
    typeof (payload as TokenPayload).id === "number" &&
    typeof (payload as TokenPayload).tipo_usuario === "string"
  );
}

// gera token
export function generateToken(payload: TokenPayload): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn });
}

// verifica token
export function verifyToken(token: string): TokenPayload {
  const decoded = jwt.verify(token, JWT_SECRET);
  if (!isTokenPayload(decoded)) {
    throw new Error("Payload do token em formato inesperado");
  }
  return decoded;
}