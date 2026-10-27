# Acceso a AWS sin tarjeta para la entrega

## Lo que bloquea el despliegue

Una cuenta AWS estandar no puede crear una EC2 hasta completar la validacion de un metodo de pago. No es un error del repositorio y no se debe intentar eludirlo. Sin una sesion AWS valida no existen `EC2_HOST` ni `EC2_SSH_KEY`, por lo que el pipeline deja el despliegue desactivado correctamente.

## Ruta recomendada: laboratorio institucional

Solicita al profesor un laboratorio de **AWS Academy Learner Lab** o **AWS Educate** con acceso a EC2. Esa via permite practicar en la consola AWS sin registrar una tarjeta personal y entrega credenciales temporales. La cuenta, los permisos, las regiones y el tiempo de vida dependen del laboratorio; por eso hay que validar que EC2 este habilitado antes de crear recursos.

Mensaje listo para enviar al profesor:

> Profesor, ya tengo el repositorio publico, Docker, CI/DevSecOps y el workflow de CD preparados. Mi cuenta personal de AWS no puede completar la validacion del medio de pago. ¿Podria habilitarme un AWS Academy Learner Lab o AWS Educate con permiso para usar EC2 en `us-east-1`? Necesito crear una instancia temporal Amazon Linux 2023 `t3.micro`, con SSH y HTTP, para ejecutar la evidencia de despliegue. Al terminar la apagare/eliminare segun la politica del laboratorio.

Fuentes oficiales: [AWS Educate](https://aws.amazon.com/education/awseducate/), [preguntas frecuentes de AWS Training](https://aws.amazon.com/training/faqs/) y [registro de cuentas AWS](https://docs.aws.amazon.com/accounts/latest/reference/getting-started.html).

## Cuando recibas el acceso

1. Inicia el laboratorio y abre **AWS Details / CloudShell**. No pegues esas credenciales en el repositorio ni en un chat.
2. En una terminal con AWS CLI, desde la raiz del proyecto ejecuta:

   ```powershell
   .\scripts\verificar-acceso-aws.ps1
   ```

   El script confirma la identidad temporal y lectura de EC2 en `us-east-1`. Si falla, copia solo el mensaje de error (sin claves) y pide al profesor que habilite EC2 o esa region.

3. Con el prechequeo verde, crea una EC2 temporal Amazon Linux 2023 `t3.micro` en `us-east-1`, aplicando [`infra/user-data.sh`](../infra/user-data.sh). El grupo de seguridad debe permitir HTTP (80) y SSH (22) solo desde tu IP actual.
4. Guarda **manualmente** en GitHub Actions los secretos `EC2_HOST` y `EC2_SSH_KEY` (contenido de la llave `.pem`); la llave no se versiona ni se comparte.
5. Crea la variable de repositorio `DEPLOY_ENABLED=true` y realiza un push o ejecuta el workflow manualmente. La verificacion final es `http://<EC2_HOST>/api/health` y debe mostrar el SHA corto desplegado.

## Alternativas, en orden

1. **AWS Academy / AWS Educate del curso:** la alternativa correcta para la evidencia académica sin tarjeta.
2. **Cuenta institucional administrada:** el profesor crea una cuenta miembro/IAM temporal y limita presupuesto y permisos. No debe compartir su usuario root.
3. **Cuenta personal estándar:** resolver la validacion únicamente con el banco y el soporte de AWS; AWS requiere un medio de pago válido para completar el registro.

Mientras llega el acceso, CI, el análisis de seguridad, Docker y los pull requests siguen funcionando. El pipeline no simula una URL de AWS: su etapa de EC2 permanece apagada para no presentar una evidencia falsa.
