CREATE DATABASE entrega_4;

-- 1. Limpieza preventiva
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS clientes;

-- 2. Creación de estructuras
CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY,
    nombre_cliente VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL
);

CREATE TABLE categorias (
    id_categoria SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL
);

CREATE TABLE productos (
    id_producto SERIAL PRIMARY KEY,
    nombre_producto VARCHAR(100) NOT NULL,
    precio NUMERIC(10,2) NOT NULL,
    id_categoria INT REFERENCES categorias(id_categoria)
);

CREATE TABLE ventas (
    id_venta SERIAL PRIMARY KEY,
    id_cliente INT REFERENCES clientes(id_cliente),
    id_producto INT REFERENCES productos(id_producto),
    cantidad INT NOT NULL,
    fecha_venta DATE NOT NULL
);

-- 3. Carga de datos de prueba
INSERT INTO categorias (nombre_categoria) VALUES ('Perifericos'), ('Tecnologia'), ('Mobiliario');

INSERT INTO productos (nombre_producto, precio, id_categoria) VALUES 
('Teclado Mecanico', 100.00, 1),
('Mouse Gamer', 50.00, 1),
('Monitor 27', 800.00, 2),
('Silla Ergonomica', 250.00, 3);

INSERT INTO clientes (nombre_cliente, email) VALUES 
('Luis Gomez', 'luis@email.com'),
('Marta Silva', 'marta@email.com'),
('Jose Perez', 'jose@email.com'); -- Cliente sin compras

INSERT INTO ventas (id_cliente, id_producto, cantidad, fecha_venta) VALUES 
(1, 1, 3, '2026-01-15'), -- Luis compró Teclado
(1, 1, 5, '2026-02-20'), -- Luis volvió a comprar Teclado (8 en total)
(1, 2, 2, '2026-03-01'), -- Luis compró Mouse (2 en total)
(2, 3, 10, '2026-02-10'),-- Marta compró Monitor ($8000 en categoria Tecnologia)
(2, 4, 1, '2026-03-15'); -- Marta compró Silla

/* ============================================================================
   SCRIPT PRE-ENTREGA MÓDULO 4: CONSULTAS MULTICAPA PARA ANÁLISIS DE NEGOCIO
   Base de Datos: PostgreSQL
   ============================================================================ */


-- ============================================================================
-- CONSULTA 1: RENTABILIDAD POR CATEGORÍA
--
-- Problema de negocio que resuelve:
-- Identifica qué líneas de productos están generando los mayores ingresos y
-- volumen de ventas para la empresa. Esto permite a la dirección estratégica
-- optimizar la asignación del presupuesto de marketing, renegociar costos con
-- proveedores clave y planificar el stock en bodega.
-- ============================================================================

-- Umbral definido en $5,000.00 porque representa la línea base de facturación 
-- mínima requerida por categoría para cubrir los costos fijos de almacenamiento 
-- y logística de distribución.

SELECT 
    cat.nombre_categoria,
    SUM(v.cantidad) AS unidades_vendidas,
    SUM(v.cantidad * p.precio) AS ingreso_total
FROM ventas AS v
INNER JOIN productos AS p 
    ON v.id_producto = p.id_producto
INNER JOIN categorias AS cat 
    ON p.id_categoria = cat.id_categoria
GROUP BY cat.id_categoria, cat.nombre_categoria
HAVING SUM(v.cantidad * p.precio) > 5000.00
ORDER BY ingreso_total DESC;


-- ============================================================================
-- CONSULTA 2: CLIENTES SIN COMPRAS
--
-- Problema de negocio que resuelve:
-- Detecta a los usuarios registrados en la plataforma que aún no han realizado
-- ninguna transacción ("leads fríos" o registros inactivos). Esta información
-- es crítica para el equipo de Marketing para ejecutar campañas de re-engagement,
-- enviar descuentos de primera compra o evaluar posibles fricciones en el flujo de checkout.
-- ============================================================================

SELECT 
    c.id_cliente,
    c.nombre_cliente,
    c.email,
    COALESCE(COUNT(v.id_venta), 0) AS total_compras,
    COALESCE(SUM(v.cantidad * p.precio), 0.00) AS total_gastado
FROM clientes AS c
LEFT JOIN ventas AS v 
    ON c.id_cliente = v.id_cliente
LEFT JOIN productos AS p 
    ON v.id_producto = p.id_producto
GROUP BY c.id_cliente, c.nombre_cliente, c.email
HAVING COUNT(v.id_venta) = 0
ORDER BY c.nombre_cliente ASC;


-- ============================================================================
-- CONSULTA 3: TOP DE COMPRAS POR CLIENTE
--
-- Problema de negocio que resuelve:
-- Determina el producto favorito de cada cliente (el que ha comprado en mayor
-- cantidad acumulada) y la fecha de su última interacción. Permite personalizar
-- recomendaciones de venta cruzada (cross-selling/up-selling) y detectar
-- clientes en riesgo de abandono (churn) según su recencia.
-- ============================================================================

WITH resumen_compras AS (
    SELECT 
        c.id_cliente,
        c.nombre_cliente,
        p.nombre_producto,
        SUM(v.cantidad) AS unidades_compradas,
        MAX(v.fecha_venta) AS fecha_ultima_transaccion,
        ROW_NUMBER() OVER (
            PARTITION BY c.id_cliente 
            ORDER BY SUM(v.cantidad) DESC, MAX(v.fecha_venta) DESC
        ) AS ranking
    FROM clientes AS c
    INNER JOIN ventas AS v 
        ON c.id_cliente = v.id_cliente
    INNER JOIN productos AS p 
        ON v.id_producto = p.id_producto
    GROUP BY c.id_cliente, c.nombre_cliente, p.id_producto, p.nombre_producto
)
SELECT 
    nombre_cliente,
    nombre_producto AS producto_mas_comprado,
    unidades_compradas,
    fecha_ultima_transaccion
FROM resumen_compras
WHERE ranking = 1
ORDER BY nombre_cliente ASC;

-- 1. Crear la tabla de regiones
CREATE TABLE regiones (
    id_region SERIAL PRIMARY KEY,
    nombre_region VARCHAR(50) NOT NULL
);

-- 2. Agregar la columna id_region a la tabla clientes
ALTER TABLE clientes 
ADD COLUMN id_region INT REFERENCES regiones(id_region);

-- 3. Cargar las regiones de prueba
INSERT INTO regiones (nombre_region) VALUES 
('Norte'), 
('Sur'), 
('Centro'), 
('Este');

-- 4. Asignar región a los clientes existentes
UPDATE clientes SET id_region = 1 WHERE id_cliente = 1; -- Luis -> Norte
UPDATE clientes SET id_region = 2 WHERE id_cliente = 2; -- Marta -> Sur
UPDATE clientes SET id_region = 3 WHERE id_cliente = 3; -- Jose -> Centro

-- 5. Agregar un cliente nuevo en la región Este y una venta para tener datos en todas las regiones
INSERT INTO clientes (nombre_cliente, email, id_region) 
VALUES ('Ana Lopez', 'ana@email.com', 4);

INSERT INTO ventas (id_cliente, id_producto, cantidad, fecha_venta) 
VALUES (4, 1, 1, '2026-03-05'); -- $100

SELECT *FROM clientes;

/* ============================================================================
   ENTREGA MÓDULO 5: INFORME DE RENDIMIENTO REGIONAL CON CTEs
   Archivo: modulo_5/analisis_ctes.sql
   Base de Datos: PostgreSQL
   ============================================================================ */

-- 1. Definición de la CTE para agrupar y sumar las ventas por región
WITH ventas_por_region AS (
    SELECT 
        r.nombre_region,
        SUM(v.cantidad * p.precio) AS total_ventas
    FROM ventas AS v
    INNER JOIN clientes AS c 
        ON v.id_cliente = c.id_cliente
    INNER JOIN regiones AS r 
        ON c.id_region = r.id_region
    INNER JOIN productos AS p 
        ON v.id_producto = p.id_producto
    GROUP BY r.id_region, r.nombre_region
)

-- 2. Consulta principal que filtra y ordena
SELECT 
    nombre_region,
    total_ventas
FROM ventas_por_region
WHERE total_ventas > (
    -- Subconsulta para calcular el promedio de todas las regiones
    SELECT AVG(total_ventas) 
    FROM ventas_por_region
)
ORDER BY total_ventas DESC;