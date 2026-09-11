import bcrypt from 'bcrypt';

const SALT_ROUNDS = 10;

async function hashPassword(senha: string): Promise<string> {
    return bcrypt.hash(senha, SALT_ROUNDS);
}

async function comparePassword(senha: string, hash: string): Promise<boolean> {
    return bcrypt.compare(senha, hash);
}

export { hashPassword, comparePassword }