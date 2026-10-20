// Punto de entrada: abre la base y enciende la API.
// Variables: PORT (3000) · RUTA_DB · APP_VERSION · APP_ENV · WEB_DIR
const { abrir } = require('./db');
const { crearApp } = require('./app');

const PORT = Number(process.env.PORT) || 3000;
const db = abrir();
const servidor = crearApp(db);

servidor.listen(PORT, () => {
  console.log(`CaféHuila API escuchando en :${PORT} · versión ${process.env.APP_VERSION || 'dev'} · entorno ${process.env.APP_ENV || 'local'}`);
});

// Docker manda SIGTERM al detener el contenedor: cerrar ordenado evita cortar pedidos a la mitad.
for (const senal of ['SIGTERM', 'SIGINT']) {
  process.on(senal, () => {
    console.log(`${senal} recibido, cerrando…`);
    servidor.close(() => { db.close(); process.exit(0); });
  });
}
