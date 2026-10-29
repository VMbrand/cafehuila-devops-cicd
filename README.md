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

¿No tienes cuenta AWS validada por tarjeta? Sigue la [ruta de acceso institucional sin tarjeta](docs/acceso-aws-sin-tarjeta.md). Incluye el mensaje para solicitar un laboratorio AWS Educate/AWS Academy y el prechequeo `scripts/verificar-acceso-aws.ps1`.

| Archivo | Propósito |
|---|---|
| `compose.yml` | Desarrollo: construye desde el código local |
| `compose.prod.yml` | Producción: descarga imágenes de GHCR por commit |
| `infra/user-data.sh` | Prepara EC2 con Docker, Compose y swap |

## Operación de producción

Antes de habilitar el despliegue se crea en AWS una EC2 `t3.micro` en `us-east-1`, un presupuesto mensual de US$5 y las alarmas de caída y CPU. Los pasos de diagnóstico, rollback y operación están en [docs/operacion.md](docs/operacion.md).

La ruta `/api/health` es el contrato de despliegue: debe devolver `estado`, `version`, `entorno` y `hora`. La versión debe coincidir con los siete primeros caracteres del commit que el pipeline publicó.

## Evidencias de la entrega

- Pull requests y checks en verde en GitHub.
- Última ejecución exitosa de CI-CD en `main`.
- Etiquetas de las imágenes en GHCR.
- URL pública y respuesta de `/api/health` cuando AWS esté habilitado.
- Alarmas CloudWatch/SNS, presupuesto y simulacro documentado.
- Postmortem en `docs/postmortems/` y métricas DORA en `docs/metricas-dora.md`.

## Métricas DORA

| Semana | Despliegues | Tiempo de entrega | Tasa de fallo | Tiempo de recuperación |
|---|---:|---|---|---|
| 2026-10-19 | Pendiente | Pendiente | Pendiente | Pendiente |

Los comandos y criterios para llenar esta tabla están en `docs/metricas-dora.md`.
