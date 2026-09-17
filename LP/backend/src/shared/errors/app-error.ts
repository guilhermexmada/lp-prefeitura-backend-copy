export class AppError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;

  constructor(
    message: string,
    statusCode: number,
    isOperational = true
  ) {
    super(message);
    this.name = "AppError";
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    Object.setPrototypeOf(this, new.target.prototype); // corrige funcionamento de instanceof em TS
    Error.captureStackTrace(this, this.constructor); // limpa logs de erro
    this.name = this.constructor.name;
  }
}

