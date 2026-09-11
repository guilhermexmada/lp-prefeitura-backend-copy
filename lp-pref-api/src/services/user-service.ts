import { prisma } from '../lib/prisma.js'
import jwt from 'jsonwebtoken'
import dotenv from 'dotenv'
import { hashPassword, comparePassword } from '../utils/hash.js'

dotenv.config()

class UserService {
    public async create(data: { nome: string; email: string; senha: string }) {
        const existente = await prisma.usuarios.findFirst({ where: { email: data.email } });

        if (existente) {
            throw new Error('EMAIL_JA_CADASTRADO')
        }

        const senha_hash = await hashPassword(data.senha);

        return prisma.usuarios.create({
            data: { nome: data.nome, email: data.email, senha_hash },
            select: {
                id: true,
                nome: true,
                email: true,
                tipo_usuario: true,
                created_at: true,
            },
        });
    }
    public async login(email: string, senha: string) {
        const usuario = await prisma.usuarios.findFirst({ where: { email } });

        // sem usuário ou sem senha_hash (caso da linha reservada do anônimo) -> nunca autentica
        if (!usuario || !usuario.senha_hash) {
            throw new Error('CREDENCIAIS_INVALIDAS');
        }

        if (!usuario.ativo) {
            throw new Error('CREDENCIAIS_INVALIDAS');
        }

        const senhaValida = await comparePassword(senha, usuario.senha_hash);
        if (!senhaValida) {
            throw new Error('CREDENCIAIS_INVALIDAS');
        }

        return usuario;
    }
}

export default new UserService()