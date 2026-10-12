import type { NextFunction, Request, Response } from 'express';
import { mapService } from './mapa.service.js';
import type { MapaTicketsQueryDTO } from './dto/mapa.dto.js';

class MapController {
    getMapaTickets = async (request: Request, response: Response, next: NextFunction) => {
        try {
            const query = request.validated?.query as MapaTicketsQueryDTO;
            const resultado = await mapService.getMapaTickets(query, request.user!);
            return response.status(200).json(resultado);
        } catch (error) {
            next(error);
        }
    };
}

export const mapController = new MapController();