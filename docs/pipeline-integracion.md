# Pipeline de integración y entrega

El proyecto separa validación, artefacto y despliegue. Cada etapa recibe solo
el resultado de la anterior:

```text
feature/* o Pull Request
        |
        v
1. npm test
        |
        v
2. Docker Compose: API + frontend + /api/health + HTTP
        |
        v
3. build Docker + Trivy
        |
        v
4. GHCR con tag SHA inmutable (solo main)
        |
        v
5. promoción controlada a EC2 + health check de producción
```

## Qué evita cada puerta

| Etapa | Falla que detecta | Evidencia |
|---|---|---|
| Pruebas | Regresión de la lógica API | `npm test` |
| Integración | API y frontend incompatibles, puertos, health check o Compose | Contenedores efímeros saludables |
| Seguridad | Vulnerabilidad crítica con arreglo | Trivy bloquea el workflow |
| Artefacto | Versión no trazable | Imagen `ghcr.io/...:<SHA>` |
| Producción | Imagen distinta, servicio caído o versión incorrecta | `/api/health` con SHA corto |

## Relación con AWS

El pipeline no crea una nueva EC2 por cada commit. La infraestructura existe una
sola vez, declarada en `infra/ec2-cafehuila.yaml`. En la cuenta AWS Project, la
promoción se ejecuta con `scripts/promover-a-ec2.ps1` porque SSH permanece
limitado a la IP administrativa y la cuenta bloquea OIDC de GitHub.

Esto mantiene tres capas claras:

```text
CI = valida código e integración
CD = promueve el artefacto validado
AWS = ejecuta y observa la versión promovida
```
