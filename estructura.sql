-- Proyecto final | Ferretería online
-- Antes de ejecutar este archivo, crear la base con:
-- CREATE DATABASE capstone_project;
-- Conectarse a capstone_project desde DBeaver o pgAdmin.

DROP VIEW IF EXISTS pedidos_limpios;
DROP TABLE IF EXISTS pedidos CASCADE;
DROP TABLE IF EXISTS productos CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;

CREATE TABLE clientes (
    cliente_id INTEGER PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    ciudad VARCHAR(80)
);

CREATE TABLE productos (
    producto_id INTEGER PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    categoria VARCHAR(70) NOT NULL,
    precio_lista NUMERIC(12,2) NOT NULL CHECK (precio_lista > 0)
);

CREATE TABLE pedidos (
    pedido_id INTEGER PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES clientes(cliente_id),
    producto_id INTEGER NOT NULL REFERENCES productos(producto_id),
    fecha_pedido DATE,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) CHECK (precio_unitario > 0),
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('Confirmado', 'Cancelado'))
);

-- Importación desde archivos CSV con encabezado (psql):
-- Ejecutar estos comandos en psql, parado en la carpeta del repositorio.
-- En DBeaver/pgAdmin, importar los CSV a las tablas con el asistente de importación.
-- \copy clientes (cliente_id,nombre,email,ciudad) FROM 'clientes.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
-- \copy productos (producto_id,nombre,categoria,precio_lista) FROM 'productos.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
-- \copy pedidos (pedido_id,cliente_id,producto_id,fecha_pedido,cantidad,precio_unitario,estado) FROM 'pedidos.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- La vista permite dejar los datos originales intactos.
-- Si falta el precio de una venta, usamos el precio de lista como aproximación.
-- Si falta la fecha, no la inventamos: ese pedido no entra en los análisis por mes.
CREATE VIEW pedidos_limpios AS
SELECT
    pe.pedido_id, pe.cliente_id, pe.producto_id,
    pe.fecha_pedido, pe.cantidad, pe.estado,
    COALESCE(pe.precio_unitario, pr.precio_lista) AS precio_unitario_limpio,
    pe.cantidad * COALESCE(pe.precio_unitario, pr.precio_lista) AS importe
FROM pedidos pe
JOIN productos pr ON pr.producto_id = pe.producto_id;
