# Presentación final — CaféHuila DevOps

## Objetivo en una frase

Demostrar que una versión de CaféHuila pasa por controles automáticos antes de
llegar a una EC2 real y que puede ser verificada, operada y recuperada de forma
trazable.

## Estado listo para demostrar

| Elemento | Estado verificable |
|---|---|
| Repositorio | Público; docente `lanvargas94` con acceso de lectura |
| Rama | `main` protegida, sin PR abiertos |
| CI | Pruebas, integración Docker y seguridad en verde |
| Producción | <http://3.145.7.158> |
| Health check | <http://3.145.7.158/api/health> |
| Release desplegado | `12d8d95` |
| Operación | Alertas CloudWatch/SNS y presupuesto configurados |

> No exponer claves SSH, claves AWS ni secretos de GitHub durante la
> presentación.

## Orden recomendado (7–10 minutos)

### 1. Problema y arquitectura — 1 minuto

"No se despliega copiando archivos manualmente. El objetivo es que cada cambio
sea probado, integrado, escaneado y trazable hasta la instancia de producción."

```text
Pull Request -> pruebas -> integración Docker -> seguridad -> GHCR (SHA)
             -> promoción controlada -> EC2 -> /api/health -> alertas
```

### 2. Código y versionamiento — 1 minuto

1. Abrir el repositorio y la rama `main`.
2. Mostrar que no hay ramas de trabajo ni Pull Requests abiertos.
3. Explicar que los cambios pasan por PR y que `main` exige controles antes de
   fusionar.

### 3. Pipeline CI/DevSecOps — 2 minutos

Abrir **Actions → CI-CD → última ejecución exitosa** y explicar cada puerta:

1. **Pruebas:** `npm test` valida la API.
2. **Integración Docker:** levanta API y frontend con Compose; exige `/api/health`
   y respuesta HTTP del frontend.
3. **Imágenes + seguridad:** construye ambas imágenes y Trivy bloquea
   vulnerabilidades críticas corregibles.
4. **GHCR:** publica una imagen con el SHA del commit, no una etiqueta ambigua
   como `latest`.

La promoción a EC2 usa la misma imagen aprobada. En esta cuenta AWS Project se
realiza desde un administrador autorizado, porque OIDC está restringido y SSH
no se abre a los runners públicos de GitHub.

### 4. Demostración local — 1 minuto

El proyecto queda levantado localmente con Docker Compose. En este equipo el
puerto 8080 está ocupado por otra aplicación, por lo que CaféHuila usa 8081:

```powershell
$env:PUERTO_WEB='8081'
docker compose ps
Invoke-RestMethod http://localhost:8081/api/health
```

Mostrar `api` y `web` saludables y luego abrir <http://localhost:8081>.

### 5. Demostración AWS real — 2 minutos

Abrir, en este orden:

1. <http://3.145.7.158>
2. <http://3.145.7.158/api/health>
3. `evidencias/estado-entrega.md` en el repositorio.

Explicar el contrato de health check: `estado`, `version`, `entorno` y `hora`.
La versión de producción debe ser `12d8d95` para el release actual.

### 6. Operación responsable — 1 minuto

Mostrar la evidencia de:

- una sola EC2 `t3.micro`;
- alarmas de caída y CPU;
- SNS confirmado;
- presupuesto de USD 5;
- SSH limitado a una IP administrativa `/32`;
- rollback por promoción de un SHA verde anterior.

## Preguntas probables y respuesta corta

| Pregunta | Respuesta |
|---|---|
| ¿Por qué no se despliega desde cualquier `push`? | Primero debe pasar pruebas, integración y seguridad; además se evita publicar cambios no revisados en producción. |
| ¿Qué prueba la integración? | Que API y frontend arrancan juntos en Docker y que los endpoints HTTP funcionan, no solo que un test unitario pase. |
| ¿Cómo sabes qué versión corre? | La imagen y `/api/health` usan el SHA corto del release. |
| ¿Cómo haces rollback? | Se promueve explícitamente el último SHA verde conocido; no se recompila en la EC2. |
| ¿Por qué el job EC2 puede aparecer omitido? | La cuenta Project bloquea OIDC y no se abre SSH a runners públicos. La promoción administrativa conserva mínimo privilegio y usa la misma imagen validada. |
| ¿Puede el docente revisar? | Sí: el repo es público y `lanvargas94` tiene acceso de lectura. El acceso a la consola AWS depende de una política institucional independiente. |

## Plan B si algo falla durante la presentación

- **La web local no abre:** usar la producción pública y mostrar `docker compose ps`.
- **El puerto 8080 no está libre:** usar el puerto 8081, como se indica arriba.
- **No hay sesión AWS activa:** mostrar la evidencia versionada, Actions y el
  health check público; no improvisar credenciales.
- **La aplicación pública no responde:** mostrar la última ejecución verde,
  las evidencias y explicar el procedimiento documentado de diagnóstico y
  rollback en `docs/operacion.md`.

## Cierre

"El resultado no es solo una aplicación encendida: es una entrega reproducible,
segura y observable, desde el commit hasta la verificación de producción."
