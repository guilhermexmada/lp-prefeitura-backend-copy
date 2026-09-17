import { AppError } from './app-error.js';

export class UnauthorizedError extends AppError {
  constructor(message = 'Não autenticado') {
    super(message, 401);
  }
}