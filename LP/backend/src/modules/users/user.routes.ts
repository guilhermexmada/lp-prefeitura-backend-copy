import { Router } from "express";
import { asyncHandler } from "../../shared/utils/async-handler.js";
import { validateBody } from "../../shared/middlewares/validate.middleware.js";
import { authMiddleware } from "../../shared/middlewares/authenticate.middleware.js";
import { authorizeMiddleware } from "../../shared/middlewares/authorize.middleware.js";
import { createUserSchema, loginUserSchema } from "./schemas/user.schema.js";
import { UserController } from "./user.controller.js";

const usersRoutes = Router();
const usersController = new UserController();

usersRoutes.post("/register", validateBody(createUserSchema), asyncHandler(usersController.register));
usersRoutes.post("/login", validateBody(loginUserSchema), asyncHandler(usersController.login));
usersRoutes.get("/me", authMiddleware, asyncHandler(usersController.me))

// rotas de teste
usersRoutes.get("/todos", authMiddleware, (req, res, next) => {
    res.send(`Rota para todos os tipos de usuários - Seu nível: ${req.user?.tipoUsuario} ${req.user?.anonymous ? 'anonimo' : 'autenticado'}`);
})
usersRoutes.get("/municipes", authMiddleware, authorizeMiddleware(['municipe'], { allowAnonymous: false }), (req, res, next) => {
    res.send(`Rota para municipes - Seu nível: ${req.user?.tipoUsuario} ${req.user?.anonymous ? 'anonimo' : 'autenticado'}`);
})
usersRoutes.get("/funcionarios", authMiddleware, authorizeMiddleware(['funcionario'], { allowAnonymous: false }), (req, res, next) => {
    res.send(`Rota para funcionarios - Seu nível: ${req.user?.tipoUsuario} ${req.user?.anonymous ? 'anonimo' : 'autenticado'}`);
})

export { usersRoutes };