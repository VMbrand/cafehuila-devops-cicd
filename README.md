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

Si el puerto 8080 ya está ocupado por otra aplicación local:

```powershell
$env:PUERTO_WEB='8081'
docker compose up --build -d --wait
```

- App: http://localhost:8080
- Salud: http://localhost:8080/api/health
- Pruebas: `cd api; npm test`
- Apagar sin borrar datos: `docker compose down`

## Pipeline

`.github/workflows/ci-cd.yml` ejecuta `npm test`, construye API y web, escanea con Trivy y publica en GHCR una imagen identificada por el SHA al integrar un cambio en `main`. La API de producción recibe `APP_ENV=produccion`; los valores locales viven en `.env`, que no se versiona.

Antes de construir la imagen, el job **Integración Docker** levanta API y frontend con Docker Compose, exige que ambos estén saludables y verifica `/api/health` y la respuesta HTTP. El detalle de cada puerta está en [docs/pipeline-integracion.md](docs/pipeline-integracion.md).

La cuenta AWS Project usada en esta práctica restringe SSH a la IP administrativa y bloquea OIDC. Por eso CI publica la imagen y la promoción usa el script restringido `scripts/promover-a-ec2.ps1`; la explicación completa está en [docs/despliegue-cuenta-project.md](docs/despliegue-cuenta-project.md). En una cuenta AWS tradicional con acceso seguro desde GitHub se puede activar `DEPLOY_FROM_GITHUB=true` para habilitar el job de EC2.

¿No tienes cuenta AWS validada por tarjeta? Sigue la [ruta de acceso institucional sin tarjeta](docs/acceso-aws-sin-tarjeta.md). Incluye el mensaje para solicitar un laboratorio AWS Educate/AWS Academy y el prechequeo `scripts/verificar-acceso-aws.ps1`.

| Archivo | Propósito |
|---|---|
| `compose.yml` | Desarrollo: construye desde el código local |
| `compose.prod.yml` | Producción: descarga imágenes de GHCR por commit |
| `infra/user-data.sh` | Prepara EC2 con Docker, Compose y swap |
| `infra/ec2-cafehuila.yaml` | Infraestructura EC2 reproducible mediante CloudFormation |

## Operación de producción

Producción usa una sola EC2 `t3.micro` en `us-east-2`, un presupuesto mensual de US$5 y alarmas de caída y CPU. Los pasos de diagnóstico, rollback y operación están en [docs/operacion.md](docs/operacion.md) y el guion de presentación en [docs/sustentacion-profesor.md](docs/sustentacion-profesor.md).

Para una demostración ordenada, consulta el [guion final de presentación](docs/presentacion-final.md).

La creación de la EC2 también está declarada como código. Consulta [el procedimiento reproducible de CloudFormation](docs/despliegue-ec2-reproducible.md) para validar una cuenta AWS, crear la infraestructura y conectarla con el pipeline.

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
