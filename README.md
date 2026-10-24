# Proyecto final SQL – Análisis de ventas de una ferretería online

## ¿De qué se trata?

Para este trabajo armé un ejemplo de una ferretería que vende por internet. La idea fue mirar sus pedidos y tratar de responder preguntas que podrían servirle a alguien que maneja el negocio: quién compra más, cómo vienen las ventas mes a mes y qué productos tienen poca salida.

**Aclaración importante:** el conjunto de datos es **simulado**, creado para practicar SQL. No representa ventas reales de una empresa ni resultados obtenidos de Kaggle. Los importes están expresados en **pesos argentinos (ARS)** y no se ajustaron por inflación.

## Archivos

- `estructura.sql`: tablas, relaciones, tipos de datos y vista de limpieza.
- `analisis.sql`: controles de calidad y seis consultas de análisis.
- `clientes.csv`, `productos.csv`, `pedidos.csv`: datos de ejemplo para importar.

## Cómo ejecutarlo

Necesitás PostgreSQL y podés usar DBeaver, pgAdmin o psql.

1. Crear una base nueva con `CREATE DATABASE capstone_project;` (este comando se ejecuta conectado a otra base, por ejemplo `postgres`).
2. Conectarte a `capstone_project` y ejecutar `estructura.sql`.
3. Importar los CSV en este orden: `clientes.csv`, `productos.csv`, `pedidos.csv`. En DBeaver se puede hacer con clic derecho sobre cada tabla > **Import Data** > CSV; activar la primera fila como encabezado y verificar que los nombres de columnas coincidan. En pgAdmin también se puede usar **Import/Export Data**. Otra alternativa es usar `\copy` desde psql; dejé ejemplos comentados en `estructura.sql`.
4. Ejecutar `analisis.sql`, ya con las tablas cargadas. Se pueden correr las consultas por separado.

**Importante:** `estructura.sql` elimina y vuelve a crear las tablas del ejemplo. No lo ejecutes en una base con información que necesites conservar.

## Datos y relaciones

- `clientes`: 12 clientes (ID, nombre, email y ciudad).
- `productos`: 15 artículos, con categoría y precio de lista.
- `pedidos`: 150 registros; cada fila representa la compra de un producto. Tiene referencias a cliente y producto, cantidad, fecha, precio unitario y estado.

La relación es **clientes 1:N pedidos** y **productos 1:N pedidos**. En este modelo sencillo cada pedido tiene un solo producto; en una tienda real probablemente agregaría una tabla de detalle de pedido.

## Limpieza y decisiones

Antes de analizar, revisé fechas y precios faltantes. Hay **2 pedidos sin fecha** y **3 con precio unitario vacío**. En PostgreSQL esos valores se cargan como `NULL`.

- Si falta el precio, la vista `pedidos_limpios` usa `COALESCE(precio_unitario, precio_lista)` para tomar el precio de lista como referencia. Es una aproximación y puede no reflejar descuentos históricos.
- Si falta la fecha, la dejo como `NULL`: no corresponde inventar el día de una venta. Esos registros quedan afuera del resumen mensual, pero sí pueden entrar en los análisis que no necesitan fecha.
- Los pedidos `Cancelado` no se cuentan como ventas. De lo contrario, estaríamos inflando los ingresos.
- `fecha_pedido` usa `DATE` y los precios usan `NUMERIC(12,2)` para evitar tratarlos como texto.

## Preguntas que respondí

1. **¿Quiénes son los 5 clientes que más gastaron?** Usé `JOIN`, `SUM`, `COUNT`, `GROUP BY` y `LIMIT`.
2. **¿Cuánto se vendió por mes?** Agrupé las fechas con `DATE_TRUNC`.
3. **¿Qué 3 productos vendieron menos unidades?** Usé `LEFT JOIN` para contemplar también artículos sin ventas.
4. **¿Qué productos lideran en cada categoría?** Armé una CTE y un `RANK()` para ordenar por facturación dentro de cada rubro.
5. **¿Hay clientes sin compras confirmadas?** Lo revisé con `LEFT JOIN` y `HAVING`.
6. **¿Qué categorías están por encima del promedio de facturación?** Usé `CASE` y funciones de ventana.

## Hallazgos con los datos de ejemplo

Los siguientes resultados se calcularon sobre los CSV incluidos. Son **resultados del ejercicio**, no conclusiones sobre un comercio real.

- El cliente con mayor gasto es **Lucía Fernández**, con **$1,541,800.00 ARS** en pedidos confirmados.
- El mes de mayor facturación, entre los pedidos con fecha informada, es **2026-01**, con **$1,575,700.00 ARS**.
- Entre los productos con menor cantidad de unidades vendidas aparecen **Casco de seguridad, Llave francesa, Bulones x 20**.
- La categoría que más factura en este ejemplo es **Herramientas eléctricas**, con **$4,957,000.00 ARS**.

## ¿Qué haría con esta información?

Primero miraría a los clientes con más gasto para pensar beneficios o promociones de fidelización. Después revisaría los productos de baja rotación antes de volver a comprarlos. También compararía las ventas mensuales con meses anteriores, pero con más información: nueve meses de datos simulados no alcanzan para afirmar que existe una tendencia estable.

Algo que me quedó claro con este trabajo es que limpiar los datos cambia la calidad de las conclusiones. Si sumo pedidos cancelados o invento fechas que faltan, puedo terminar presentando números que no representan bien lo que pasó.

## Limitaciones

Este ejemplo no incluye devoluciones, costos, márgenes ni descuentos por operación. Por eso hablamos de **facturación**, no de ganancia. Además, como los datos son inventados, los hallazgos sirven para demostrar las consultas y no para tomar decisiones comerciales reales.
