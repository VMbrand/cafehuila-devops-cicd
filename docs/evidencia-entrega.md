# Evidencia verificable de la entrega

El proyecto tiene dos niveles de evidencia que no se deben confundir:

1. **Local y automatizado:** Docker Compose, endpoint `/api/health`, pruebas, escaneo de seguridad, imágenes y las plantillas CloudFormation.
2. **AWS real:** identidad de la cuenta, usuario `revisor-docente` con `ReadOnlyAccess`, disponibilidad de EC2, instancia, IP pública y health check remoto.

Para generar un reporte actual sin exponer secretos, desde la raíz del repositorio se ejecuta:

```powershell
.\scripts\generar-evidencia-entrega.ps1 -Profile cafehuila-advanced -Region us-east-1
```

El resultado se guarda en `evidencias/estado-entrega.md`. El reporte no incluye contraseñas, `SECRET_ACCESS_KEY`, contenido de archivos PEM ni una IP ficticia.

## Uso durante la revisión

- Si EC2 aparece como **HABILITADO**, se ejecuta el despliegue reproducible y se regenera el reporte con la IP y el health check remoto.
- Si EC2 aparece como **BLOQUEADO/PENDIENTE DE ACTIVACIÓN**, el informe acredita el estado real de la cuenta y evita afirmar que hubo un despliegue inexistente.
- El formato de Moodle que solicita cuenta, IP y credenciales solo se llena cuando todos sus datos sean reales. Este reporte es evidencia complementaria; no reemplaza ese formato.

## Qué demuestra el proyecto

```text
Rama/PR -> CI -> pruebas -> análisis de seguridad -> imagen Docker
-> CloudFormation -> EC2 -> health check -> CloudWatch/budget -> revisión de solo lectura
```
