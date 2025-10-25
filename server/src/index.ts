import { Elysia } from 'elysia'
import { websocket } from './websocket'

export  const server = new Elysia()
.get('/', () => {
    return 'Hello Luke3D';
})
.use(websocket)
.listen(8080, (e) => {
    console.log(`Server running on http://localhost:${e.port}`);
});