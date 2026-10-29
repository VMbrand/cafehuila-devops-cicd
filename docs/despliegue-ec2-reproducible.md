# EC2 reproducible para CafeHuila

La aplicacion no se compila en la EC2. El circuito real es:

```text
feature/* -> pull request -> pruebas -> imagenes + Trivy -> main
                                                      -> GHCR -> EC2 -> /api/health
```

La misma imagen identificada por el SHA del commit pasa por CI y luego llega a la instancia. [`ci-cd.yml`](../.github/workflows/ci-cd.yml) impide construir/publicar/desplegar si las pruebas previas no pasan.

## Precondiciones de una cuenta AWS valida

- Sesion temporal o cuenta AWS activa con EC2 y CloudFormation habilitados en `us-east-1`.
- Permisos para consultar VPC/subredes, crear `AWS::EC2::Instance` y `AWS::EC2::SecurityGroup`.
- Una VPC y subred **publica** existentes; se pasan como parametros para no asumir que toda cuenta tiene VPC predeterminada.
- Un key pair creado desde la consola AWS. Su archivo `.pem` es privado: no se sube al repositorio ni se comparte.
- La IP publica actual en formato `x.x.x.x/32`; SSH queda restringido a esa IP.

El control real de acceso es:

```powershell
.\scripts\preflight-ec2-aws.ps1 -Profile curso -Region us-east-1
```

Si indica que EC2 no esta disponible, no se intenta crear recursos ni se registra una evidencia falsa. La cuenta actual de este proyecto autentica, pero AWS devuelve `OptInRequired` al consultar EC2; el administrador del laboratorio debe habilitar EC2 o entregar una cuenta/laboratorio que ya lo tenga activo.

## Crear la infraestructura una vez habilitada la cuenta

Primero ubica una VPC y subred publica de la cuenta habilitada. Crea el key pair desde la consola y conserva la llave `.pem` fuera del repositorio. Luego ejecuta, sustituyendo los valores reales:

```powershell
.\scripts\desplegar-ec2-aws.ps1 `
  -Profile curso `
  -VpcId vpc-... `
  -PublicSubnetId subnet-... `
  -KeyName cafehuila-deploy `
  -AdminCidr 203.0.113.10/32 `
  -Confirmar
```

El parámetro `-Confirmar` es obligatorio: crear la pila aprovisiona una EC2 `t3.micro`, un volumen cifrado gp3 de 12 GB y un grupo de seguridad. La plantilla usa Amazon Linux 2023, IMDSv2 obligatorio y `DeleteOnTermination`; al borrar la pila se eliminan esos recursos creados por ella.

Al finalizar, CloudFormation muestra `PublicIp`. Ese valor se guarda en el secreto de GitHub `EC2_HOST`. El contenido privado de la `.pem` se guarda manualmente como `EC2_SSH_KEY`. Por ultimo, se activa `DEPLOY_ENABLED=true` y el push a `main` ejecuta el despliegue y comprueba `/api/health`.
