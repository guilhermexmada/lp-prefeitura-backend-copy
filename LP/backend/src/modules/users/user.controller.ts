import type { Request, Response } from "express";
import { z } from "zod";
import { generateToken } from "../../shared/utils/jwt.js";
import { userService } from "./user.service.js";

// validações com ZOD
const registerSchema = z.object({
  nome: z.string().min(1).optional(),
  email: z.string().email(),
  senha: z.string().min(6),
});

const loginSchema = z.object({
  email: z.string().email(),
  senha: z.string().min(1),
});

export class UserController {
  register = async (request: Request, response: Response) => {
    const { nome, email, senha } = registerSchema.parse(request.body);

    const usuario = await userService.create({
      nome,
      email,
      senha,
    });

    const token = generateToken({
      id: usuario.id,
      tipo_usuario: usuario.tipoUsuario,
    });

    response.status(201).json({
      usuario: {
        id: usuario.id,
        nome: usuario.name,
        email: usuario.email,
        tipo_usuario: usuario.tipoUsuario,
        created_at: usuario.createdAt,
      },
      token,
    });
  };

  login = async (request: Request, response: Response) => {
    const { email, senha } = loginSchema.parse(request.body);

    const usuario = await userService.login(email, senha);

    const token = generateToken({
      id: usuario.id,
      tipo_usuario: usuario.tipoUsuario,
    });

    response.status(200).json({
      usuario: {
        id: usuario.id,
        nome: usuario.name,
        email: usuario.email,
        tipo_usuario: usuario.tipoUsuario,
        created_at: usuario.createdAt,
      },
      token,
    });
  };

  me = async (request: Request, response: Response) => {
    response.status(200).json(request.user);
  };
}
