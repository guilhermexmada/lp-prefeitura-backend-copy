import { prisma } from "../../shared/database/prisma.js";
import { AppError } from "../../shared/errors/app-error.js";
import { comparePassword, hashPassword } from "../../shared/utils/hash.js";

interface CreateUserInput {
  nome?: string;
  email: string;
  senha: string;
}

class UserService {
  async create(data: CreateUserInput) {
    const existente = await prisma.user.findFirst({
      where: {
        email: data.email,
      },
    });

    if (existente) {
      throw new AppError("Já existe um cadastro com esse e-mail", 409);
    }

    const passwordHash = await hashPassword(data.senha);

    return prisma.user.create({
      data: {
        name: data.nome,
        email: data.email,
        passwordHash,
      },
      select: {
        id: true,
        name: true,
        email: true,
        tipoUsuario: true,
        createdAt: true,
      },
    });
  }

  async login(email: string, senha: string) {
    const usuario = await prisma.user.findFirst({
      where: {
        email,
      },
    });

    if (!usuario || !usuario.passwordHash || !usuario.ativo) {
      throw new AppError("E-mail ou senha inválidos", 401);
    }

    const senhaValida = await comparePassword(
      senha,
      usuario.passwordHash,
    );

    if (!senhaValida) {
      throw new AppError("E-mail ou senha inválidos", 401);
    }

    return usuario;
  }
}

export const userService = new UserService();
