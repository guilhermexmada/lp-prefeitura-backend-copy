import { Request, Response, NextFunction } from 'express'
import UserService from '../services/user-service.js'
import { generateToken } from '../utils/jwt.js';
// import { UUIDTypes, v4 as uuidv4 } from 'uuid'

class UserController {
    // método de cadastro
    public async register(req: Request, res: Response, next: NextFunction) {
        try {
            const { nome, email, senha } = req.body
            if (!email || !senha) {
                return res.status(400).json({ error: 'email e senha são obrigatórios' });
            }
            const data = {
                nome,
                email,
                senha
            }
            const usuario = await UserService.create(data)
            const token = generateToken({ id: usuario.id, tipo_usuario: usuario.tipo_usuario });
            res.status(201).json({ success: true, message: 'Cadastro realizado com sucesso', data: { usuario, token } })
        } catch (error: unknown) {
            if (error instanceof Error && error.message === 'EMAIL_JA_CADASTRADO') {
                return res.status(409).json({ error: 'Já existe um cadastro com esse e-mail' });
            } else {
                res.status(500).json({ message: 'Erro interno do servidor', error })
            }
        }
    }
    // método de login
    public async login(req: Request, res: Response, next: NextFunction) {
        try {
            const { email, senha } = req.body;

            if (!email || !senha) {
                return res.status(400).json({ error: 'email e senha são obrigatórios' });
            }

            const usuario = await UserService.login(email, senha);
            const token = generateToken({ id: usuario.id, tipo_usuario: usuario.tipo_usuario });

            res.status(200).json({
                success: true,
                message: 'Login realizado com sucesso',
                data: {
                    usuario: {
                        id: usuario.id,
                        nome: usuario.nome,
                        email: usuario.email,
                        tipo_usuario: usuario.tipo_usuario,
                        created_at: usuario.created_at,
                    },
                    token,
                }
            });
        } catch (error) {
            if (error instanceof Error && error.message === 'CREDENCIAIS_INVALIDAS') {
                return res.status(401).json({ error: 'E-mail ou senha inválidos' });
            }
            throw error;
        }
    }
}

export default new UserController()