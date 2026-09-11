import express, { Application, Request, Response } from 'express'
import { appRoutes } from './routes/index.js'

const app: Application = express()

// configs
app.use(express.static('public'))
app.use(express.urlencoded({ extended: true }))
app.use(express.json())

// rotas
app.use('/api', appRoutes)

app.get('/', (req: Request, res: Response) => {
    res.redirect('/api/health')
})

export default app