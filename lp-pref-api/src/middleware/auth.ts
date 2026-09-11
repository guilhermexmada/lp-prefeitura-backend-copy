import type { Request, Response, NextFunction } from 'express';
import { verifyToken, type TokenPayload } from '../utils/jwt.js';

declare global {
  namespace Express {
    interface Request {
      user?: TokenPayload;
    }
  }
}

export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token não fornecido' });
  }

  const token = authHeader.split(' ')[1];

  try {
    req.user = verifyToken(token);
    next();
  } catch {
    return res.status(401).json({ error: 'Token inválido ou expirado' });
  }
}