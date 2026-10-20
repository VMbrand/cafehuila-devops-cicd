# CaféHuila · Docker, CI/CD y operación

Este repositorio avanza por etapas: Docker local, integración continua, despliegue a AWS y operación de producción.

## Flujo de ramas

- `main`: versión integrada y lista para desplegar.
- `feature/<tema>`: cambio acotado; se integra mediante pull request con los checks en verde.
- Los commits usan prefijos como `feat:`, `fix:`, `ci:`, `docs:` y `test:`.

## Desarrollo local

```powershell
Copy-Item .env.example .env
docker compose up --build -d --wait
```

- App: http://localhost:8080
- Salud: http://localhost:8080/api/health
- Pruebas: `cd api; npm test`
- Apagar sin borrar datos: `docker compose down`

## Pipeline

`.github/workflows/ci-cd.yml` ejecuta pruebas, construye API y web, escanea con Trivy y publica en GHCR al integrar un cambio en `main`.

El despliegue a EC2 queda protegido por la variable de repositorio `DEPLOY_ENABLED`. Antes de habilitarla se debe crear la EC2 y configurar los secretos `EC2_HOST` y `EC2_SSH_KEY`; después, en **Settings → Secrets and variables → Actions → Variables**, cree `DEPLOY_ENABLED=true`.

| Archivo | Propósito |
|---|---|
| `compose.yml` | Desarrollo: construye desde el código local |
| `compose.prod.yml` | Producción: descarga imágenes de GHCR por commit |
| `infra/user-data.sh` | Prepara EC2 con Docker, Compose y swap |
