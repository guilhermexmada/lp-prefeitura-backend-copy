import { prisma } from '../lib/prisma.js'

class HealthService {
    public async healthCheck(): Promise<Object> {
        // query para verificar estado do banco
        await prisma.$queryRaw`SELECT 1`
        // objeto final de healthcheck
        return {
            api: 'online',
            uptime: process.uptime(),
            timestamp: new Date().toISOString(),
            database: 'online'
        }
    }
}

export default new HealthService()