import bcrypt from "bcrypt";

const SALT_ROUNDS = 10;

// hasheia senha
export async function hashPassword(senha: string): Promise<string> {
  return bcrypt.hash(senha, SALT_ROUNDS);
}

// compara senha e hash (retorna true/false)
export async function comparePassword(senha: string, hash: string): Promise<boolean> {
  return bcrypt.compare(senha, hash);
}