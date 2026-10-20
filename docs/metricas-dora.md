# Métricas DORA

Registre datos reales después de tener al menos dos despliegues exitosos en `main`.

| Semana | Despliegues | Tiempo de entrega | Tasa de fallo | Tiempo de recuperación |
|---|---:|---|---|---|
| 2026-10-19 | Pendiente | Pendiente | Pendiente | Pendiente |

En Git Bash, desde la raíz del repositorio:

```bash
gh run list --workflow ci-cd.yml --branch main --event push --limit 50
gh pr list --state merged --json number,createdAt,mergedAt
```

- Frecuencia de despliegue: ejecuciones exitosas de CI-CD a `main` por semana.
- Tiempo de entrega: tiempo del PR integrado más la duración del pipeline.
- Tasa de fallo: ejecuciones fallidas a `main` entre ejecuciones totales.
- Tiempo de recuperación: desde un flujo rojo hasta el siguiente verde, o desde T0 hasta T2 del simulacro.
