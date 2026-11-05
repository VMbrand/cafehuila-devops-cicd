# Despliegue en una cuenta AWS Project

La cuenta de producción usa la experiencia AWS Project. Permite EC2 y
CloudFormation, pero su política administrada bloquea OIDC de GitHub. Abrir SSH
a todo Internet para compensarlo no es aceptable.

La estrategia aplicada es:

```text
push a main -> pruebas -> escaneo -> imagen inmutable en GHCR
                                    |
                                    +-> promoción administrativa restringida -> EC2
```

La promoción usa exactamente la imagen que aprobó CI, nunca compila en la EC2.
SSH sigue limitado al CIDR administrativo indicado en `infra/ec2-cafehuila.yaml`.

## Promover una versión validada

Desde la raíz del repositorio:

```powershell
.\scripts\promover-a-ec2.ps1 `
  -PublicHost 3.145.7.158 `
  -KeyPath .\secrets\cafehuila-deploy-20261104.pem `
  -Tag (git rev-parse HEAD) `
  -Confirmar
```

El script copia `compose.prod.yml`, descarga la imagen inmutable desde GHCR,
arranca los contenedores, limpia capas antiguas y exige que `/api/health`
devuelva el SHA corto esperado.

Si en el futuro se usa una cuenta AWS tradicional con OIDC disponible, se puede
activar `DEPLOY_FROM_GITHUB=true` para que el job `3 · Desplegar en EC2` use los
secretos SSH existentes. En una cuenta Project se mantiene `false` o sin definir
para no exponer el puerto 22 a los runners hospedados por GitHub.
