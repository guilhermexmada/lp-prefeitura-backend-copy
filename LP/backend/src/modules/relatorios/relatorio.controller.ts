import { Request, Response } from "express";
import { PeriodoQueryDTO } from "./dtos/relatorio.dto.js";
import { relatorioService } from "./relatorio.service.js";

class RelatorioController {
    getIndicadores = async (request: Request, response: Response) => {
        const query = request.validated?.query as PeriodoQueryDTO;

        const result = await relatorioService.getIndicadores(query);

        response.status(200).json(result);
    }
    getVolumeSemanal = async (request: Request, response: Response) => {
        const query = request.validated?.query as PeriodoQueryDTO;

        const result = await relatorioService.getVolumeSemanal(query);

        response.status(200).json(result);
    }
    getTicketsPorCategoria = async (request: Request, response: Response) => {
        const query = request.validated?.query as PeriodoQueryDTO;

        const result = await relatorioService.getTicketsPorCategoria(query);

        response.status(200).json(result);
    }
    getDesempenhoPorDepartamento = async (request: Request, response: Response) => {
        const query = request.validated?.query as PeriodoQueryDTO;

        const result = await relatorioService.getDesempenhoPorDepartamento(query);

        response.status(200).json(result);
    }
}

export const relatorioController = new RelatorioController(); 