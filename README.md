# CaféHuila · con Docker (solución de la Sesión 1)

```bash
cp .env.example .env
docker compose up --build      # http://localhost:8080
docker compose ps              # api y web deben quedar "healthy"
docker compose down            # apaga (los pedidos quedan en el volumen "datos")
docker compose down -v         # apaga y BORRA los datos
```

| Servicio | Imagen | Puerto | Qué hace |
|---|---|---|---|
| `web` | nginx:1.27-alpine | 8080 → 80 | sirve el front y pasa `/api/` a la API |
| `api` | node:22-alpine (3 etapas) | 3000 (solo red interna) | pedidos + sqlite en el volumen `datos` |

Sin Docker también corre: `cd api && npm start` → http://localhost:3000
