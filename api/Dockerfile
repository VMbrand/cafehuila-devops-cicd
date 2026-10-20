# API de CaféHuila en tres etapas:
#   base  -> lo común (Node 22 + el código)
#   test  -> corre las pruebas: `docker build --target test api` (si fallan, ese build falla)
#   prod  -> lo que se despliega: sin pruebas, usuario sin privilegios, health check
# Ojo: `--target prod` (lo que usa compose) SE SALTA la etapa test. Por eso el pipeline
# corre las pruebas en su propio job antes de construir la imagen.
FROM node:22-alpine AS base
WORKDIR /app
COPY package.json ./
# Este proyecto no tiene dependencias npm. En uno que sí tenga: COPY package-lock.json + RUN npm ci --omit=dev
COPY src ./src

FROM base AS test
COPY test ./test
RUN node --test

FROM base AS prod
# La versión la pone el pipeline (--build-arg APP_VERSION=<commit>); en la laptop queda "dev".
ARG APP_VERSION=dev
ENV NODE_ENV=production \
    PORT=3000 \
    RUTA_DB=/data/cafehuila.db \
    APP_VERSION=${APP_VERSION}
RUN mkdir -p /data && chown node:node /data
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/api/health >/dev/null || exit 1
CMD ["node", "src/server.js"]
