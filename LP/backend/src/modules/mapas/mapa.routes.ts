import { Router } from 'express';
import { authMiddleware } from '../../shared/middlewares/authenticate.middleware.js';
import { authorizeMiddleware } from '../../shared/middlewares/authorize.middleware.js';
import { validateQuery } from '../../shared/middlewares/validate.middleware.js';
import { mapController } from './mapa.controller.js';
import { mapaTicketsQuerySchema } from './schemas/mapa.schema.js';

const mapRoutes = Router();

// Autenticação e papel aplicados no router inteiro, como nos relatórios
// mapRoutes.use(authMiddleware, authorizeMiddleware('gestor'));
mapRoutes.get('/', validateQuery(mapaTicketsQuerySchema), mapController.getMapaTickets);

export { mapRoutes };