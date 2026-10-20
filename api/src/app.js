// La API de CaféHuila: rutas y validaciones. No arranca nada: server.js la enciende
// y las pruebas la usan con una base en memoria.
//
//   GET  /api/health     estado + versión desplegada (la usan Docker, el pipeline y usted)
//   GET  /api/productos  catálogo
//   GET  /api/pedidos    últimos 20 pedidos
//   POST /api/pedidos    { cliente, producto_id, cantidad }  ->  201 | 400
//
// Si existe la carpeta del front (WEB_DIR o ../web/public) también la sirve: así corre
// "en mi máquina" con un solo `node`. Dentro de Docker esa carpeta no existe y nginx
// se encarga del front.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const TIPOS = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8', '.svg': 'image/svg+xml', '.ico': 'image/x-icon' };

function crearApp(db, opciones = {}) {
  const version = opciones.version || process.env.APP_VERSION || 'dev';
  const entorno = opciones.entorno || process.env.APP_ENV || 'local';
  const webDir = opciones.webDir !== undefined ? opciones.webDir
    : (process.env.WEB_DIR || path.join(__dirname, '..', '..', 'web', 'public'));

  function json(res, codigo, cuerpo) {
    res.writeHead(codigo, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(cuerpo));
  }

  function leerCuerpo(req) {
    return new Promise((ok, falla) => {
      let datos = '';
      req.on('data', (c) => { datos += c; if (datos.length > 10_000) falla(new Error('muy grande')); });
      req.on('end', () => { try { ok(datos ? JSON.parse(datos) : {}); } catch (e) { falla(e); } });
    });
  }

  function validarPedido(p) {
    const errores = [];
    const cliente = typeof p.cliente === 'string' ? p.cliente.trim() : '';
    if (!cliente || cliente.length > 60) errores.push('cliente: obligatorio, máximo 60 caracteres');
    const cantidad = Number(p.cantidad);
    if (!Number.isInteger(cantidad) || cantidad < 1 || cantidad > 20) errores.push('cantidad: entero entre 1 y 20');
    const producto = db.prepare('SELECT * FROM productos WHERE id = ?').get(Number(p.producto_id) || 0);
    if (!producto) errores.push('producto_id: no existe');
    return { errores, cliente, cantidad, producto };
  }

  async function manejar(req, res) {
    const url = new URL(req.url, 'http://localhost');
    const ruta = url.pathname;

    if (req.method === 'GET' && ruta === '/api/health') {
      return json(res, 200, { estado: 'ok', version, entorno, hora: new Date().toISOString() });
    }
    if (req.method === 'GET' && ruta === '/api/productos') {
      return json(res, 200, db.prepare('SELECT * FROM productos ORDER BY id').all());
    }
    if (req.method === 'GET' && ruta === '/api/pedidos') {
      return json(res, 200, db.prepare(`
        SELECT p.id, p.cliente, p.cantidad, p.total, p.creado, pr.nombre AS producto
        FROM pedidos p JOIN productos pr ON pr.id = p.producto_id
        ORDER BY p.id DESC LIMIT 20`).all());
    }
    if (req.method === 'POST' && ruta === '/api/pedidos') {
      let cuerpo;
      try { cuerpo = await leerCuerpo(req); } catch { return json(res, 400, { errores: ['JSON inválido'] }); }
      const { errores, cliente, cantidad, producto } = validarPedido(cuerpo);
      if (errores.length) return json(res, 400, { errores });
      const total = producto.precio * cantidad;
      const r = db.prepare('INSERT INTO pedidos (cliente, producto_id, cantidad, total) VALUES (?, ?, ?, ?)')
        .run(cliente, producto.id, cantidad, total);
      return json(res, 201, { id: Number(r.lastInsertRowid), cliente, producto: producto.nombre, cantidad, total });
    }
    if (ruta.startsWith('/api/')) return json(res, 404, { error: 'ruta no encontrada' });

    // Front estático (solo cuando corre fuera de Docker)
    if (req.method === 'GET' && webDir && fs.existsSync(webDir)) {
      const archivo = path.normalize(path.join(webDir, ruta === '/' ? 'index.html' : ruta));
      if (archivo.startsWith(path.normalize(webDir)) && fs.existsSync(archivo) && fs.statSync(archivo).isFile()) {
        res.writeHead(200, { 'Content-Type': TIPOS[path.extname(archivo)] || 'application/octet-stream' });
        return fs.createReadStream(archivo).pipe(res);
      }
    }
    return json(res, 404, { error: 'no encontrado' });
  }

  return http.createServer((req, res) => {
    manejar(req, res).catch((e) => {
      console.error(e);
      json(res, 500, { error: 'error interno' });
    });
  });
}

module.exports = { crearApp };
