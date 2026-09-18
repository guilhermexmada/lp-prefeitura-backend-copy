// shared/middlewares/authorize.middleware.ts
import { Request, Response, NextFunction } from 'express';
import { TokenPayload } from '../types/token-payload.js';
import { TipoUsuario } from '@prisma/client';
import { UnauthorizedError } from '../errors/unauthorized-error.js';
import { ForbiddenError } from '../errors/forbidden-error.js';

export function authorizeMiddleware(...allowedTypes: TipoUsuario[]) {
    return (req: Request, res: Response, next: NextFunction) => {
        const user = req.user as TokenPayload;

        if (!user) {
            throw new UnauthorizedError('Usuário não autenticado');
        }

        if (!allowedTypes.includes(user.tipoUsuario)) {
            throw new ForbiddenError(`Acesso restrito a: ${allowedTypes.join(', ')}`);
        }

        return next();
    };
}