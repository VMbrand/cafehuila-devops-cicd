# Evidencia técnica — CaféHuila DevOps

Generado: **2026-11-04 22:15 -05:00**

> Reporte de hechos verificados. No contiene contraseñas, claves privadas ni secretos de AWS o GitHub.

## Trazabilidad de la entrega

- Repositorio: `VMbrand/cafehuila-devops-cicd` (público para revisión).
- Rama principal protegida: `main`.
- Release desplegado: `12d8d955a7758a7324228c36a03d3c488143f7c0`.
- Health de producción: versión `12d8d95`.
- Ejecución CI/CD aprobada: [run 41955359512](https://github.com/VMbrand/cafehuila-devops-cicd/actions/runs/41955359512).

## Validación continua e integración

La ejecución de `main` terminó en **success** y confirmó: pruebas de API, integración Docker (API, frontend, `/api/health` y respuesta web), construcción de imágenes, escaneo Trivy y publicación en GHCR.

La protección de `main` exige `2 · Integración Docker` y `3 · Imágenes + seguridad` antes de aceptar cambios.

## Producción AWS real

- Cuenta: `902020936517`; región: `us-east-2` (`us-east-2a`).
- Instancia: `i-011fb144f3b88586f`, tipo `t3.micro`, estado **running**.
- IP pública: `3.145.7.158`.
- Aplicación: <http://3.145.7.158>.
- Health check: <http://3.145.7.158/api/health>.
- Contenedores `api` y `web`: **healthy** con la imagen SHA del release.

La promoción usa `scripts/promover-a-ec2.ps1`: EC2 descarga la imagen validada en CI y no compila código en producción. SSH permanece limitado al CIDR administrativo actual `/32`; HTTP es el único acceso público de la app.

## Operación y observabilidad

- Alarmas CloudWatch `cafehuila-caida` y `cafehuila-cpu-alta`: **OK**.
- SNS `cafehuila-alertas`: suscripción por correo confirmada.
- Presupuesto operativo configurado en el stack `cafehuila-operacion`.

## Acceso de revisión

- El código, documentación, historial y pipeline se revisan desde el repositorio público.
- Existe el usuario AWS `revisor-docente`; la organización AWS Project restringe su login de consola mediante una política central. No se afirma acceso de consola hasta que su administrador lo habilite.

## Conclusión

La aplicación está desplegada y verificable en AWS; el pipeline de integración está aprobado y la operación dispone de alertas. La única dependencia externa para una revisión de consola es habilitar el usuario de solo lectura, sin afectar la revisión pública del repositorio ni del endpoint desplegado.
