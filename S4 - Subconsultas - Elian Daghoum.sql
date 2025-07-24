-- ------------------------------------------ 
-- NIVEL 1
-- 1
-- Realiza una subconsulta que muestre a todos los usuarios 
-- con más de 80 transacciones utilizando al menos 2 mesas.
-- ------------------------------------------ 

-- Creamos una subconsulta que busca los id de los que hayan hecho más compras de 80 de la tabla transactions. 
-- Creamos la consulta para rescatar el nombre y apellido de la tabla users


SELECT u.id, u.name, u.surname, recuento.compras_total
FROM (
  SELECT user_id, COUNT(id) AS compras_total
  FROM transactions_t4
  GROUP BY user_id
  HAVING COUNT(id) > 80
  ) AS Recuento
JOIN users u ON Recuento.user_id = u.id; 


-- ------------------------------------------ 
-- NIVEL 1
-- 2
-- Muestra la media de amount por IBAN de las tarjetas de crédito a la compañía Donec Ltd, utiliza al menos 2 tablas.
-- ------------------------------------------ 

-- juntamos las tablas transactions, credit cards y company. Creamos la medai de gasto y agrupamos por IBAN asegurandonos de que la compañía sea la exigida.

SELECT ROUND(AVG(t.amount),2) AS 'Media de gasto', cc.iban, c.company_name
FROM transactions_t4 t
JOIN credit_cards cc ON t.card_id = cc.id
JOIN company c ON t.business_id = c.company_id
WHERE c.company_name = 'Donec Ltd'
GROUP BY cc.iban;


-- ------------------------------------------ 
-- NIVEL 2
-- 1
-- Crea una nueva tabla que refleje el estado de las tarjetas de crédito 
-- y responde a la consulta: ¿Cuántas tarjetas están activas?
-- ------------------------------------------

SELECT COUNT(*) AS Tarjetas_activas
FROM tarjetas_status
WHERE Estado = 'activa';

SELECT *  
FROM tarjetas_status
WHERE Estado = 'activa';
-- ------------------------------------------ 
-- NIVEL 3
-- 1
-- número de veces que se ha vendido cada producto
-- ------------------------------------------

SELECT tp.producto_id, p.product_name, COUNT(transaccion_id) AS ventas_totales
FROM transacciones_productos tp
JOIN products p ON tp.producto_id = p.id
JOIN transactions_t4 t ON tp.transaccion_id = t.id
WHERE declined = 0
GROUP BY tp.producto_id
ORDER BY ventas_totales DESC;


