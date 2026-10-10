import { Request, Response, NextFunction } from "express";
import { PeriodoQueryDTO, PorCategoriaQueryDTO } from "./dtos/relatorio.dto.js";
import { relatorioService } from "./relatorio.service.js";

class RelatorioController{
    getAllRelatorios = async (request: Request, response: Response) => {
        const query = request.validated?.query as PeriodoQueryDTO;

        const result = await relatorioService.getIndicadores(query);

        response.status(200).json(result);
    }
}

export const relatorioController = new RelatorioController(); 