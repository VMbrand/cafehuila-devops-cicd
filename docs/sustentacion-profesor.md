# Sustentación técnica — CafeHuila DevOps

## Idea central

No se trata de "subir una aplicación". El proyecto asegura que una versión
recorra una cadena controlada:

```text
Rama y Pull Request -> pruebas npm -> imagen Docker -> escaneo Trivy
-> GHCR con SHA inmutable -> promoción controlada -> EC2 -> /api/health
-> CloudWatch, SNS y presupuesto
```

## Evidencia demostrable

| Tema | Evidencia |
|---|---|
| Versionamiento | PR, protección de `main` y commit trazable |
| Calidad | `npm test` antes de construir imágenes |
| Seguridad | Trivy bloquea vulnerabilidades críticas corregibles |
| Inmutabilidad | Producción descarga `ghcr.io/...:<SHA>`; no compila en EC2 |
| Infraestructura | CloudFormation crea EC2, red mínima, cifrado e IMDSv2 |
| Operación | `/api/health`, alarmas de caída/CPU, SNS y presupuesto USD 5 |
| Costos | Una sola `t3.micro`, 12 GiB, sin RDS, ALB ni segunda VM |

## Decisión de seguridad relevante

SSH está limitado a la IP administrativa. La cuenta AWS Project bloquea OIDC,
por lo que no se abrió el puerto 22 para los runners de GitHub. La promoción
administrativa usa `scripts/promover-a-ec2.ps1`, descarga la misma imagen que
CI aprobó y exige el health check con el SHA esperado.

## Comandos de demostración

```powershell
.\scripts\verificar-produccion.ps1 `
  -PublicHost 3.145.7.158 `
  -ExpectedTag <SHA_DESPLEGADO> `
  -KeyPath .\secrets\cafehuila-deploy-20261104.pem
```

`SHA_DESPLEGADO` es el valor de `~/app/desplegado.env` en la EC2, no
necesariamente el último commit de documentación en el repositorio.

Para rollback, se promociona explícitamente un SHA verde anterior:

```powershell
.\scripts\promover-a-ec2.ps1 `
  -PublicHost 3.145.7.158 `
  -KeyPath .\secrets\cafehuila-deploy-20261104.pem `
  -Tag <SHA_VERDE_ANTERIOR> `
  -Confirmar
```

Después de la práctica, la EC2 se puede detener sin borrarla:

```powershell
.\scripts\detener-ec2.ps1 -InstanceId i-011fb144f3b88586f -Confirmar
```
