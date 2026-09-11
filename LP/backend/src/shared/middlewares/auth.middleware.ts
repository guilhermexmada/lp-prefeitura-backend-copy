import type { NextFunction, Request, Response } from "express";
import { AppError } from "../errors/app-error.js";
import { verifyToken, type TokenPayload } from "../utils/jwt.js";

declare global {
  namespace Express {
    interface Request {
      user?: TokenPayload;
    }
  }
}

export function authMiddleware(request: Request, _response: Response, next: NextFunction) {
  const authHeader = request.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    throw new AppError("Token não fornecido", 401);
  }

  try {
    request.user = verifyToken(authHeader.split(" ")[1]);
    next();
  } catch {
    throw new AppError("Token inválido ou expirado", 401);
  }
}