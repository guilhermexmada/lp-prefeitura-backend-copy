import { Router } from 'express';
import { authMiddleware } from '../../shared/middlewares/authenticate.middleware.js';
import { authorizeMiddleware } from '../../shared/middlewares/authorize.middleware.js';
import { asyncHandler } from '../../shared/utils/async-handler.js';
import { validateQuery } from '../../shared/middlewares/validate.middleware.js';
import { periodoQuerySchema } from './schemas/relatorio.schema.js';
import { relatorioController } from './relatorio.controller.js';

const relatorioRoutes = Router();
relatorioRoutes.use(authMiddleware, authorizeMiddleware('gestor'));

relatorioRoutes.get('/indicadores', validateQuery(periodoQuerySchema), asyncHandler(relatorioController.getIndicadores));
relatorioRoutes.get('/volume', validateQuery(periodoQuerySchema), asyncHandler(relatorioController.getVolumeSemanal));
relatorioRoutes.get('/categorias', validateQuery(periodoQuerySchema), asyncHandler(relatorioController.getTicketsPorCategoria));
relatorioRoutes.get('/departamentos', validateQuery(periodoQuerySchema), asyncHandler(relatorioController.getDesempenhoPorDepartamento));

export { relatorioRoutes };