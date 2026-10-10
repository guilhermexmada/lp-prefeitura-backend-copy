import { Router } from 'express';
import { authMiddleware } from '../../shared/middlewares/authenticate.middleware.js';
import { authorizeMiddleware } from '../../shared/middlewares/authorize.middleware.js';
import { asyncHandler } from '../../shared/utils/async-handler.js';
import { validateQuery } from '../../shared/middlewares/validate.middleware.js';
import { periodoQuerySchema } from './schemas/relatorio.schema.js';
import { relatorioController } from './relatorio.controller.js';

const relatorioRoutes = Router();
relatorioRoutes.use(authMiddleware, authorizeMiddleware('gestor'));

relatorioRoutes.get('/', validateQuery(periodoQuerySchema), asyncHandler(relatorioController.getAllRelatorios));

export { relatorioRoutes };