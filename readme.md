Preparación de la Base de Datos
Para ejecutar la consulta de análisis regional sobre la base de datos previa (entrega_4), 
se incorporó la tabla regiones y se vinculó a la tabla clientes mediante claves foráneas.

-- 1. Crear la tabla de regiones
CREATE TABLE regiones (
    id_region SERIAL PRIMARY KEY,
    nombre_region VARCHAR(50) NOT NULL
);

-- 2. Vincular la tabla clientes con regiones
ALTER TABLE clientes 
ADD COLUMN id_region INT REFERENCES regiones(id_region);

-- 3. Cargar regiones de prueba
INSERT INTO regiones (nombre_region) VALUES 
('Norte'), 
('Sur'), 
('Centro'), 
('Este');

-- 4. Asignar regiones a los clientes existentes
UPDATE clientes SET id_region = 1 WHERE id_cliente = 1; -- Luis Gomez -> Norte
UPDATE clientes SET id_region = 2 WHERE id_cliente = 2; -- Marta Silva -> Sur
UPDATE clientes SET id_region = 3 WHERE id_cliente = 3; -- Jose Perez -> Centro

-- 5. Cargar un nuevo cliente y venta en la región Este
INSERT INTO clientes (nombre_cliente, email, id_region) 
VALUES ('Ana Lopez', 'ana@email.com', 4);

INSERT INTO ventas (id_cliente, id_producto, cantidad, fecha_venta) 
VALUES (4, 1, 1, '2026-03-05');

Consulta Principal (modulo_5/analisis_ctes.sql)

/* ============================================================================
   ENTREGA MÓDULO 5: INFORME DE RENDIMIENTO REGIONAL CON CTEs
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

-- 2. Consulta principal que filtra las regiones por encima del promedio general
SELECT 
    nombre_region,
    total_ventas
FROM ventas_por_region
WHERE total_ventas > (
    SELECT AVG(total_ventas) 
    FROM ventas_por_region
)
ORDER BY total_ventas DESC;

 Explicación Lógica de la Solución

Expresión Común de Tabla (WITH ventas_por_region):
Une las tablas ventas, clientes, regiones y productos.
Realiza la multiplicación 
cantidad * precio para calcular el ingreso total por transacción.
Agrupa los datos por región mediante GROUP BY y calcula la suma total (SUM).
Asigna el alias obligatorio total_ventas al total calculado.

Filtrado Dinámico en la Consulta Principal:
Consume los resultados de la CTE como si fuese una tabla virtual.
La subconsulta (SELECT AVG(total_ventas) FROM ventas_por_region) calcula el promedio general entre todas las regiones registradas.
El filtro WHERE compara el total de cada región contra dicho promedio y conserva solo las regiones con desempeño superior.
Ordena los resultados de manera descendente (DESC).

📊 Resultados Obtenidos
Desglose de Facturación por Región
Sur: $8,250.00 (10 Monitores + 1 Silla Ergonómica)
Norte: $900.00 (8 Teclados Mecánicos + 2 Mouses Gamer)
Este: $100.00 (1 Teclado Mecánico)
Centro: $0.00 (Sin ventas)

Salida de la Consulta Final

nombre_region
total_ventasSur
8250.00