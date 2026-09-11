import { Request, Response, NextFunction } from 'express'
import HealthService from '../services/health-service.js'

class HealthController {
    public async healthCheck(req: Request, res: Response, next: NextFunction) {
        try {
            const data = await HealthService.healthCheck()
            res.status(200).json({ success: true, message: 'API funcionando', data })
        } catch (error: unknown) {
            console.error('Health check falhou:', error);
            res.status(503).json({ status: 'error', api: 'down' });
        }
    }
}

export default new HealthController()