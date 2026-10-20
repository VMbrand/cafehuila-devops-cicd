# CaféHuila · con CI (Sesión 2)

Todo lo de la Sesión 1 más **`.github/workflows/ci.yml`**: en cada push o PR corre
1 · pruebas → 2 · construye las imágenes y las escanea con Trivy; en `main` además las publica en GHCR.
`.github/dependabot.yml` abre PRs solos cuando hay actualizaciones.

```bash
cp .env.example .env
docker compose up --build      # http://localhost:8080
```

Siga `Paso_a_Paso_Sesion2.md`.
