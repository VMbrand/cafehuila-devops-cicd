# Evidencia técnica — CafeHuila DevOps

Generado: **2026-10-29 22:30:35 -05:00**

> Este reporte diferencia resultados reales de simulaciones locales. No contiene contraseñas, claves secretas ni una IP inventada.

## Trazabilidad del repositorio

- Rama: `codex/evidencia-verificable`
- Commit: `4b759e4`
- Infraestructura declarada: `infra/ec2-cafehuila.yaml`
- Pipeline: `.github/workflows/ci-cd.yml`
- Operación: `infra/operacion-cafehuila.yaml`

## Infraestructura como código

- Validación `cfn-lint`: **OK** para las plantillas EC2 y operación.

## Validación local

```text
NAME                               IMAGE                                                                     COMMAND                  SERVICE   CREATED        STATUS                  PORTS
06_proyecto_cafehuila_cicd-api-1   06_proyecto_cafehuila_cicd-api                                            "docker-entrypoint.s…"   api       24 hours ago   Up 24 hours (healthy)   3000/tcp
06_proyecto_cafehuila_cicd-web-1   sha256:189aebc1597c3340ac8616f130eec69ba6c73d76ec8b36d5dbac35185b4f4b71   "/docker-entrypoint.…"   web       9 days ago     Up 9 days (healthy)     0.0.0.0:8080->80/tcp, [::]:8080->80/tcp
```
- Health check local: **OK**
```json
{"estado":"ok","version":"dev","entorno":"desarrollo","hora":"2026-10-30T03:30:47.553Z"}
```

## AWS: identidad y revisión

- Perfil AWS validado: **cafehuila-advanced**
- Cuenta: `883188969549`
- Principal: `arn:aws:iam::883188969549:root`
- Usuario de revisión: `revisor-docente`
- Políticas directas: **ReadOnlyAccess**

## AWS: disponibilidad de EC2

- EC2 en `us-east-1`: **BLOQUEADO/PENDIENTE DE ACTIVACIÓN**
- Respuesta AWS: `aws: [ERROR]: An error occurred (OptInRequired) when calling the DescribeVpcs operation: You are not subscribed to this service. Please go to http://aws.amazon.com to subscribe.`
- No se creó una EC2 ni se declara una IP pública para evitar evidencia falsa.

## Conclusión de entrega

La aplicación, CI/CD, infraestructura como código y el usuario de solo lectura están preparados. El único bloqueo externo es la activación de EC2 de AWS; no debe sustituirse por una simulación al llenar el formato obligatorio de Moodle.
