// Front de CaféHuila: llama a la API por rutas relativas (/api/...), así funciona igual
// con un solo node en la laptop, con nginx en Docker y en la EC2.
const pesos = (n) => '$' + n.toLocaleString('es-CO');

async function cargarProductos() {
  const productos = await (await fetch('/api/productos')).json();
  document.getElementById('productos').innerHTML = productos
    .map((p) => `<option value="${p.id}">${p.nombre} · ${pesos(p.precio)}</option>`).join('');
}

async function cargarPedidos() {
  const pedidos = await (await fetch('/api/pedidos')).json();
  const filas = document.getElementById('pedidos');
  filas.replaceChildren(...pedidos.map((p) => {
    const tr = document.createElement('tr');
    for (const v of [p.id, p.cliente, p.producto, p.cantidad, pesos(p.total)]) {
      const td = document.createElement('td');
      td.textContent = v;            // textContent: el nombre del cliente nunca se interpreta como HTML
      tr.append(td);
    }
    return tr;
  }));
}

async function cargarVersion() {
  const h = await (await fetch('/api/health')).json();
  document.getElementById('version').textContent = `versión ${h.version} · entorno ${h.entorno}`;
}

document.getElementById('form-pedido').addEventListener('submit', async (e) => {
  e.preventDefault();
  const datos = Object.fromEntries(new FormData(e.target));
  const r = await fetch('/api/pedidos', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ...datos, producto_id: Number(datos.producto_id), cantidad: Number(datos.cantidad) }),
  });
  const cuerpo = await r.json();
  const msg = document.getElementById('mensaje');
  msg.textContent = r.ok ? `Pedido #${cuerpo.id} registrado: ${pesos(cuerpo.total)}` : cuerpo.errores.join(' · ');
  msg.className = r.ok ? 'ok' : 'error';
  if (r.ok) { e.target.reset(); cargarPedidos(); }
});

cargarProductos();
cargarPedidos();
cargarVersion();
