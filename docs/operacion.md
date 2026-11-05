# Operación de producción

## Preparación única de AWS

1. Crear una EC2 `t3.micro` con Amazon Linux 2023 en `us-east-2`, el Security Group con HTTP 80 y SSH 22 restringido al CIDR administrativo, y el contenido de `infra/user-data.sh` como *user data*.
3. Guardar la llave `.pem` fuera del repositorio y restringir sus permisos.
4. Guardar la IP y la llave solo como secretos de Actions si la cuenta permite un canal seguro desde GitHub. En una cuenta AWS Project, usar `scripts/promover-a-ec2.ps1` y no abrir SSH para runners hospedados.
5. Crear `DEPLOY_ENABLED=true` solo después de comprobar que la EC2 responde por SSH. `DEPLOY_FROM_GITHUB=true` requiere una cuenta con OIDC/SSH seguro.
6. Crear presupuesto y alarmas mediante `scripts/desplegar-operacion-aws.ps1`; el script solicita una confirmación explícita antes de crear SNS, CloudWatch y Budget.

## Diagnóstico

Desde el navegador o terminal local, consulte:

```text
http://<EC2_HOST>/api/health
```

La verificación reproducible combina endpoint, versión y contenedores:

```powershell
.\scripts\verificar-produccion.ps1 -PublicHost <EC2_HOST> -ExpectedTag <SHA> -KeyPath .\secrets\clave.pem
```

En la EC2, cargue el commit desplegado y consulte el estado sin cambiar nada:

```bash
cd ~/app
export IMAGEN=ghcr.io/vmbrand/cafehuila-devops-cicd
export $(cat desplegado.env)
docker compose -f compose.prod.yml ps
docker compose -f compose.prod.yml logs --since 15m api
docker compose -f compose.prod.yml logs --tail 30 web
docker stats --no-stream
free -h
df -h /
```

| Señal | Umbral | Acción inicial |
|---|---|---|
| EC2 caída | `StatusCheckFailed >= 1`, 2 periodos de 5 min | Revisar la consola, reiniciar y ver logs del sistema |
| CPU alta | `CPUUtilization > 80%`, 2 periodos de 5 min | Revisar `docker stats` y logs de la API |
| Salud incorrecta | La versión no coincide después de 10 intentos | Revisar el job de verificación y ejecutar rollback |
| Base de datos | Servicio `unhealthy` o disco cerca del 80% | Revisar logs, volumen y espacio disponible |

## Alertas y costos

La plantilla `infra/operacion-cafehuila.yaml` crea un tema SNS `<proyecto>-alertas`, las alarmas `<proyecto>-caida` y `<proyecto>-cpu-alta`, y un presupuesto mensual de US$5 con alerta al 80%. Se despliega después de tener el ID de EC2:

```powershell
.\scripts\desplegar-operacion-aws.ps1 `
  -InstanceId i-... `
  -AlertEmail correo@institucion.edu `
  -Confirmar
```

AWS enviará una confirmación a ese correo: la suscripción SNS no queda activa hasta que el destinatario la confirme. Probar el correo con `aws cloudwatch set-alarm-state` antes de considerarlas listas.

Detenga la EC2 entre sesiones con `scripts/detener-ec2.ps1`. Al iniciarla, actualice `EC2_HOST` porque la IP pública puede cambiar y ejecute de nuevo la promoción de una versión verde.

## Rollback

1. Seleccione un SHA verde anterior en GHCR.
2. Ejecute `scripts/promover-a-ec2.ps1` con ese SHA y `-Confirmar`; el script valida el health check.
3. Corrija el historial con `git revert --no-edit <commit-malo>` y haga push a `main` mediante un PR. Es la corrección definitiva.

No use `latest`: las imágenes se identifican por el SHA completo del commit para que el rollback sea verificable.
