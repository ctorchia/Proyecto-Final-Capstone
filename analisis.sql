-- Proyecto final | Consultas de negocio
-- Todas las ventas consideradas son pedidos confirmados.

-- 0. Control previo: nos interesa saber qué datos faltan antes de sacar conclusiones.
SELECT
    COUNT(*) AS pedidos_totales,
    COUNT(*) FILTER (WHERE fecha_pedido IS NULL) AS sin_fecha,
    COUNT(*) FILTER (WHERE precio_unitario IS NULL) AS sin_precio,
    COUNT(*) FILTER (WHERE estado = 'Cancelado') AS cancelados
FROM pedidos;

-- 1. Top 5 clientes: sirve para ver quiénes concentran más compras y pensar acciones de fidelización.
SELECT c.cliente_id, c.nombre,
       COUNT(pl.pedido_id) AS compras,
       SUM(pl.importe) AS gasto_total
FROM clientes c
JOIN pedidos_limpios pl ON pl.cliente_id = c.cliente_id
WHERE pl.estado = 'Confirmado'
GROUP BY c.cliente_id, c.nombre
ORDER BY gasto_total DESC, c.nombre
LIMIT 5;

-- 2. Ventas por mes: ayuda a identificar meses fuertes y meses que conviene revisar.
-- Los pedidos sin fecha quedan afuera porque no sabemos a qué mes corresponden.
SELECT TO_CHAR(DATE_TRUNC('month', pl.fecha_pedido), 'YYYY-MM') AS mes,
       COUNT(*) AS pedidos_confirmados,
       SUM(pl.importe) AS facturacion
FROM pedidos_limpios pl
WHERE pl.estado = 'Confirmado' AND pl.fecha_pedido IS NOT NULL
GROUP BY DATE_TRUNC('month', pl.fecha_pedido)
ORDER BY mes;

-- 3. Los 3 productos menos vendidos: útil para revisar rotación y futuras compras.
-- LEFT JOIN incluye productos que podrían no tener ventas.
SELECT pr.producto_id, pr.nombre, pr.categoria,
       COALESCE(SUM(pl.cantidad), 0) AS unidades_vendidas
FROM productos pr
LEFT JOIN pedidos_limpios pl
       ON pl.producto_id = pr.producto_id AND pl.estado = 'Confirmado'
GROUP BY pr.producto_id, pr.nombre, pr.categoria
ORDER BY unidades_vendidas ASC, pr.nombre
LIMIT 3;

-- 4. Ranking dentro de cada categoría: muestra cuáles son los productos que más facturan.
WITH ventas_por_producto AS (
    SELECT pr.categoria, pr.nombre, pr.producto_id,
           COALESCE(SUM(pl.importe), 0) AS facturacion
    FROM productos pr
    LEFT JOIN pedidos_limpios pl
           ON pl.producto_id = pr.producto_id AND pl.estado = 'Confirmado'
    GROUP BY pr.categoria, pr.nombre, pr.producto_id
)
SELECT categoria, nombre, facturacion,
       RANK() OVER (PARTITION BY categoria ORDER BY facturacion DESC) AS posicion_categoria
FROM ventas_por_producto
ORDER BY categoria, posicion_categoria, nombre;

-- 5. Clientes sin compras confirmadas: posibles contactos para una campaña de reactivación.
SELECT c.cliente_id, c.nombre, c.email
FROM clientes c
LEFT JOIN pedidos pl
       ON pl.cliente_id = c.cliente_id AND pl.estado = 'Confirmado'
GROUP BY c.cliente_id, c.nombre, c.email
HAVING COUNT(pl.pedido_id) = 0
ORDER BY c.nombre;

-- 6. Participación por categoría: CASE separa categorías con mayor o menor peso relativo.
WITH ventas_categoria AS (
    SELECT pr.categoria, SUM(pl.importe) AS total
    FROM pedidos_limpios pl
    JOIN productos pr ON pr.producto_id = pl.producto_id
    WHERE pl.estado = 'Confirmado'
    GROUP BY pr.categoria
)
SELECT categoria, total,
       ROUND(100.0 * total / NULLIF(SUM(total) OVER (), 0), 2) AS porcentaje_total,
       CASE WHEN total >= AVG(total) OVER () THEN 'Sobre el promedio'
            ELSE 'Bajo el promedio' END AS comparacion
FROM ventas_categoria
ORDER BY total DESC;
