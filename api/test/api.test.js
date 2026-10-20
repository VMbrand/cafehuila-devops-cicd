// Pruebas de la API con el runner que trae Node (node --test): sin Jest, sin dependencias.
// Cada prueba levanta la app en un puerto libre con una base en memoria.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { abrir } = require('../src/db');
const { crearApp } = require('../src/app');

let servidor, base;

before(async () => {
  servidor = crearApp(abrir(':memory:'), { version: 'test', webDir: '' });
  await new Promise((ok) => servidor.listen(0, ok));
  base = `http://127.0.0.1:${servidor.address().port}`;
});

after(() => servidor.close());

const post = (cuerpo) => fetch(`${base}/api/pedidos`, {
  method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(cuerpo),
});

test('GET /api/health responde ok con la versión', async () => {
  const r = await fetch(`${base}/api/health`);
  assert.equal(r.status, 200);
  const cuerpo = await r.json();
  assert.equal(cuerpo.estado, 'ok');
  assert.equal(cuerpo.version, 'test');
});

test('GET /api/productos trae la semilla', async () => {
  const productos = await (await fetch(`${base}/api/productos`)).json();
  assert.equal(productos.length, 5);
  assert.ok(productos[0].precio > 0);
});

test('POST /api/pedidos válido devuelve 201 y calcula el total', async () => {
  const r = await post({ cliente: 'Ana', producto_id: 1, cantidad: 2 });
  assert.equal(r.status, 201);
  const pedido = await r.json();
  assert.equal(pedido.total, 64000);
});

test('POST /api/pedidos inválido devuelve 400 con los errores', async () => {
  const r = await post({ cliente: '', producto_id: 999, cantidad: 0 });
  assert.equal(r.status, 400);
  const { errores } = await r.json();
  assert.equal(errores.length, 3);
});

test('una ruta que no existe devuelve 404', async () => {
  const r = await fetch(`${base}/api/no-existe`);
  assert.equal(r.status, 404);
});
