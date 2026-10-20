// Acceso a datos: node:sqlite (Node >= 22.5), cero dependencias npm.
// RUTA_DB decide dónde vive el archivo; ':memory:' sirve para las pruebas.
const { DatabaseSync } = require('node:sqlite');
const fs = require('node:fs');
const path = require('node:path');

const SEMILLA = [
  ['Café de origen Huila 500 g', 32000],
  ['Café tostado La Plata 250 g', 18000],
  ['Achira de Altamira', 6500],
  ['Bizcocho de achira x 10', 9000],
  ['Tinto en vaso', 2500],
];

function abrir(ruta = process.env.RUTA_DB || path.join(__dirname, '..', 'datos', 'cafehuila.db')) {
  if (ruta !== ':memory:') fs.mkdirSync(path.dirname(ruta), { recursive: true });
  const db = new DatabaseSync(ruta);
  db.exec(`
    CREATE TABLE IF NOT EXISTS productos (
      id     INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT    NOT NULL,
      precio INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS pedidos (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      cliente     TEXT    NOT NULL,
      producto_id INTEGER NOT NULL REFERENCES productos(id),
      cantidad    INTEGER NOT NULL,
      total       INTEGER NOT NULL,
      creado      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  `);
  const { n } = db.prepare('SELECT COUNT(*) AS n FROM productos').get();
  if (n === 0) {
    const ins = db.prepare('INSERT INTO productos (nombre, precio) VALUES (?, ?)');
    for (const [nombre, precio] of SEMILLA) ins.run(nombre, precio);
  }
  return db;
}

module.exports = { abrir };
