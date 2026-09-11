import { Router } from "express";
import { authMiddleware } from "../../shared/middlewares/auth.middleware.js";
import { asyncHandler } from "../../shared/utils/async-handler.js";
import { UserController } from "./user.controller.js";

const usersRoutes = Router();
const usersController = new UserController();

usersRoutes.post("/register", asyncHandler(usersController.register));
usersRoutes.post("/login", asyncHandler(usersController.login));
usersRoutes.get("/me", authMiddleware, asyncHandler(usersController.me));

export { usersRoutes };