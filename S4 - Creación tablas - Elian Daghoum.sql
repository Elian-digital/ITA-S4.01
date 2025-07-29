CREATE DATABASE IF NOT EXISTS t4;
USE t4;
 
 -- -----------------------------------------
-- Creamos la tabla dimension users 
 -- -----------------------------------------
 CREATE TABLE IF NOT EXISTS users (
	id CHAR(10) PRIMARY KEY,
	name VARCHAR(100),
	surname VARCHAR(100),
	phone VARCHAR(150),
	email VARCHAR(150),
	birth_date DATE,
	country VARCHAR(150),
	city VARCHAR(150),
	postal_code VARCHAR(100),
	address VARCHAR(255)    
);

-- averiguamos donde está la carpeta para poder dejar los csv y cargarlos a la tabla

SHOW VARIABLES LIKE 'secure_file_priv';


-- unimos las dos tablas de usuarios en una, para hacer el modelo más sencillo y eficiente
-- Cargamos los usuarios europeos en users

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/european_users.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  id, name, surname, phone, email, @birth_date, country, city, postal_code, address
)
SET birth_date = STR_TO_DATE(@birth_date, '%b %e, %Y');

-- Cargamos los usuarios americanos en users

 LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/american_users.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  id, name, surname, phone, email, @birth_date, country, city, postal_code, address
)
SET birth_date = STR_TO_DATE(@birth_date, '%b %e, %Y');

-- vamos a modificar la tabla para añadir la columna region

ALTER TABLE users
ADD COLUMN region ENUM('Europa', 'America') DEFAULT NULL;

SELECT DISTINCT country
FROM users
ORDER BY country;

-- Asignar Europa
UPDATE users
SET region = 'Europa'
WHERE country IN (
    'France', 'Germany', 'Italy',
    'Netherlands', 'Poland', 'Portugal',
    'Spain', 'Sweden', 'United Kingdom')
    AND id IS NOT NULL;

-- Asignar América
UPDATE users
SET region = 'America'
WHERE country IN ('Canada', 'United States')
 AND id IS NOT NULL;




-- -----------------------------------------
-- Creamos la tabla companies
-- -----------------------------------------
 
  -- Creamos la tabla company
    CREATE TABLE IF NOT EXISTS company (
        company_id VARCHAR(15) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15),
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(255)
    );

-- cargamos los datos
    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv'
INTO TABLE company
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  company_id, company_name, phone, email, country, website
);
 
-- -----------------------------------------
-- Creamos la tabla Credit_card
-- -----------------------------------------
 
CREATE TABLE IF NOT EXISTS credit_cards (
        id VARCHAR(20) PRIMARY KEY,
        user_id CHAR(10),
        iban VARCHAR(34) NOT NULL,
        pan VARCHAR(50) NOT NULL, 
        pin CHAR(4)NOT NULL,
        cvv CHAR(3)NOT NULL,
        track1 VARCHAR(250) NOT NULL,
        track2 VARCHAR(250) NOT NULL,
        expiring_date DATE,
        FOREIGN KEY (user_id) REFERENCES users(id)
        );

-- creamos un enlace con la tabla users
-- cargamos los datos

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  id, user_id, iban, pan, pin, cvv, track1, track2, @expiring_date
)
SET expiring_date = STR_TO_DATE(@expiring_date, '%m/%d/%y');

-- -----------------------------------------
-- Creamos la tabla products
-- -----------------------------------------
 
CREATE TABLE IF NOT EXISTS products (
        id VARCHAR(20) PRIMARY KEY,
        product_name VARCHAR(200),
        price DECIMAL(10, 2),
        colour VARCHAR(10), 
        weight DECIMAL(10, 2),
        warehouse_id VARCHAR(50)
        );


  -- cargamos los datos

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  id, product_name, @price, colour, weight, warehouse_id
)
SET price = CAST(SUBSTRING(@price, 2) AS DECIMAL(10,2));
;

-- -----------------------------------------
-- Creamos la tabla transaction
-- -----------------------------------------
 
    CREATE TABLE IF NOT EXISTS transactions_t4 (
        id VARCHAR(255) PRIMARY KEY,
        card_id VARCHAR(15),
        business_id VARCHAR(100), 
        timestamp TIMESTAMP,
        amount DECIMAL(10, 2),
        declined BOOLEAN,
        product_ids VARCHAR(255), 
        user_id CHAR(10),
        lat FLOAT,
        longitude FLOAT,
        FOREIGN KEY (card_id) REFERENCES credit_cards(id),
		FOREIGN KEY (business_id) REFERENCES company(company_id),
		FOREIGN KEY (user_id) REFERENCES users(id) 
    );
    
    
     -- cargamos los datos, ajustando los parámetros de la instrucción. 
     -- A diferencia de las otras tablas, que usaban comas (,) como delimitador, este archivo venía exportado con punto y coma (;)
     -- añadimos los enlaces al resto de tablas a través de las id.
     
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
INTO TABLE transactions_t4
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  id, card_id, business_id, timestamp, amount, declined, product_ids, user_id, lat, longitude
) ;
    

-- ------------------------------------------ 
-- NIVEL 2
-- 1
-- Crea una nueva tabla que refleje el estado de las tarjetas de crédito 
-- basado en si las últimas tres transacciones fueron declinadas. 
-- ------------------------------------------ 


CREATE TABLE Tarjetas_status AS
SELECT card_id AS Tarjeta, 
CASE 
       WHEN SUM(CASE WHEN declined = 1 THEN 1 ELSE 0 END) = 3 THEN 'inactiva' 
       ELSE 'activa' END AS Estado
FROM ( SELECT card_id, declined, ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY t.timestamp DESC) AS fila 
	   FROM transactions_t4 t) AS tabla
WHERE fila <= 3
GROUP BY card_id
;

-- ------------------------------------------
-- NIVEL 3
-- 1
-- Crea una tabla con la que podamos unir los datos del nuevo archivo products.csv con la base de datos creada, teniendo en cuenta 
-- que desde transaction tienes product_ids. 
--  número de veces que se ha vendido cada producto
-- ------------------------------------------

CREATE TABLE transacciones_productos AS
SELECT 
    t.id AS transaccion_id,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.product_ids, ',', n.n + 1), ',', -1)) AS producto_id
FROM transactions_t4 t
JOIN (
    SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
) n ON n.n < LENGTH(t.product_ids) - LENGTH(REPLACE(t.product_ids, ',', '')) + 1
WHERE 
    SUBSTRING_INDEX(SUBSTRING_INDEX(t.product_ids, ',', n.n + 1), ',', -1) != '';

ALTER TABLE transacciones_productos
ADD CONSTRAINT fk_transaccion
FOREIGN KEY (transaccion_id) REFERENCES transactions_t4(id);

ALTER TABLE transacciones_productos
ADD CONSTRAINT fk_producto
FOREIGN KEY (producto_id) REFERENCES products(id);
