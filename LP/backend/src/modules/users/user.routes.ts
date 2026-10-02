import { Router } from 'express';
import { asyncHandler } from '../../shared/utils/async-handler.js';
import {
  validateBody,
  validateParams,
  validateQuery,
} from '../../shared/middlewares/validate.middleware.js';
import { authMiddleware } from '../../shared/middlewares/authenticate.middleware.js';
import { authorizeMiddleware } from '../../shared/middlewares/authorize.middleware.js';
import {
  createFuncionarioBodySchema,
  createUserSchema,
  getManyFuncionariosQuerySchema,
  loginUserSchema,
  setDepartamentosBodySchema,
  updateUserBodySchema,
  userIdParamsSchema,
} from './schemas/user.schema.js';
import { UserController } from './user.controller.js';

const usersRoutes = Router();
const usersController = new UserController();

usersRoutes.use(authMiddleware)

/* 
  ROTAS LIVRES
  - cadastro
  - login
  - auto consulta
*/
usersRoutes.post(
  '/register',
  validateBody(createUserSchema),
  asyncHandler(usersController.register),
);
usersRoutes.post(
  '/login',
  validateBody(loginUserSchema),
  asyncHandler(usersController.login),
);

usersRoutes.get('/me', authMiddleware, asyncHandler(usersController.me));

/*
  ROTAS GESTOR
  - cadastro de funcionários
  - edição geral *
  - deleção lógica geral *
  - atualização de departamento
  - consulta de funcionários + busca
*/
usersRoutes.post(
  '/funcionario',
  authorizeMiddleware('gestor'),
  validateBody(createFuncionarioBodySchema),
  asyncHandler(usersController.createFuncionario)
)

usersRoutes.patch(
  '/:id',
  authorizeMiddleware('gestor'),
  validateParams(userIdParamsSchema),
  validateBody(updateUserBodySchema),
  asyncHandler(usersController.update),
);

usersRoutes.delete(
  '/:id',
  authorizeMiddleware('gestor'),
  validateParams(userIdParamsSchema),
  asyncHandler(usersController.remove),
);

usersRoutes.put(
  '/:id/departamentos',
  authorizeMiddleware('gestor'),
  validateParams(userIdParamsSchema),
  validateBody(setDepartamentosBodySchema),
  asyncHandler(usersController.setDepartamentos),
);

usersRoutes.get(
  '/funcionarios',
  authorizeMiddleware('gestor'),
  validateQuery(getManyFuncionariosQuerySchema),
  asyncHandler(usersController.getManyFuncionarios),
)

export { usersRoutes };
