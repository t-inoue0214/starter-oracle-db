-- Module 7 実習: サンプルスキーマとデータの一括作成
-- 使用方法: sqlplus / as sysdba @/workspaces/starter-oracle-db/module-07-objects/setup-schema.sql

SET FEEDBACK ON
SET ECHO ON

-- PDB（XEPDB1）に切り替える
ALTER SESSION SET CONTAINER = XEPDB1;

PROMPT
PROMPT === 既存リソースのクリーンアップ ===
PROMPT

BEGIN
  EXECUTE IMMEDIATE 'DROP USER obj_user CASCADE';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

PROMPT
PROMPT === obj_user の作成 ===
PROMPT

CREATE USER obj_user IDENTIFIED BY ObjUser#1
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA 100M ON users;

GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE, CREATE VIEW TO obj_user;

PROMPT
PROMPT === テーブルの作成（制約付き） ===
PROMPT

-- 顧客テーブル
CREATE TABLE obj_user.customers (
  customer_id NUMBER(5)     CONSTRAINT pk_customers       PRIMARY KEY,
  name        VARCHAR2(50)  CONSTRAINT nn_customers_name  NOT NULL,
  email       VARCHAR2(100) CONSTRAINT uq_customers_email UNIQUE,
  birthdate   DATE,
  created_at  DATE          DEFAULT SYSDATE
);

-- 商品テーブル
CREATE TABLE obj_user.products (
  product_id NUMBER(5)    CONSTRAINT pk_products       PRIMARY KEY,
  name       VARCHAR2(50) CONSTRAINT nn_products_name  NOT NULL,
  category   VARCHAR2(20),
  price      NUMBER(10,2) CONSTRAINT chk_products_price CHECK (price > 0),
  created_at DATE         DEFAULT SYSDATE
);

-- 注文テーブル
CREATE TABLE obj_user.orders (
  order_id    NUMBER(10) CONSTRAINT pk_orders          PRIMARY KEY,
  customer_id NUMBER(5)  CONSTRAINT fk_orders_customer REFERENCES obj_user.customers(customer_id),
  product_id  NUMBER(5)  CONSTRAINT fk_orders_product  REFERENCES obj_user.products(product_id),
  qty         NUMBER(5)  DEFAULT 1 CONSTRAINT chk_orders_qty CHECK (qty >= 1),
  order_date  DATE       DEFAULT SYSDATE
);

PROMPT
PROMPT === サンプルデータの投入 ===
PROMPT

-- customers（5行）
INSERT INTO obj_user.customers (customer_id, name, email, birthdate) VALUES (1, 'Alice', 'alice@example.com', DATE '1990-05-12');
INSERT INTO obj_user.customers (customer_id, name, email, birthdate) VALUES (2, 'Bob',   'bob@example.com',   DATE '1985-11-30');
INSERT INTO obj_user.customers (customer_id, name, email, birthdate) VALUES (3, 'Carol', 'carol@example.com', DATE '1992-03-08');
INSERT INTO obj_user.customers (customer_id, name, email, birthdate) VALUES (4, 'Dave',  'dave@example.com',  DATE '1988-07-22');
INSERT INTO obj_user.customers (customer_id, name, email, birthdate) VALUES (5, 'Eve',   'eve@example.com',   DATE '1995-01-15');
COMMIT;

-- products（6行、カテゴリは Electronics / Furniture / Books）
INSERT INTO obj_user.products (product_id, name, category, price) VALUES (1, 'Laptop',    'Electronics', 120000);
INSERT INTO obj_user.products (product_id, name, category, price) VALUES (2, 'Mouse',     'Electronics',   3500);
INSERT INTO obj_user.products (product_id, name, category, price) VALUES (3, 'Keyboard',  'Electronics',   8000);
INSERT INTO obj_user.products (product_id, name, category, price) VALUES (4, 'Desk',      'Furniture',    45000);
INSERT INTO obj_user.products (product_id, name, category, price) VALUES (5, 'Chair',     'Furniture',    35000);
INSERT INTO obj_user.products (product_id, name, category, price) VALUES (6, 'SQL Guide', 'Books',         4500);
COMMIT;

-- orders（8行、Eve は注文なし）
INSERT INTO obj_user.orders (order_id, customer_id, product_id, qty, order_date) VALUES (1001, 1, 1, 1, DATE '2024-01-10');
INSERT INTO obj_user.orders (order_id, customer_id, product_id, qty, order_date) VALUES (1002, 2, 2, 3, DATE '2024-01-15');
INSERT INTO obj_user.orders (order_id, customer_id, product_id, qty, order_date) VALUES (1003, 1, 3, 1, DATE '2024-02-01');
INSERT INTO obj_user.orders (order_id, customer_id, product_id, qty, order_date) VALUES (1004, 3, 4, 1, DATE '2024-02-10');
INSERT INTO obj_user.orders (order_id, customer_id, product_id, qty, order_date) VALUES (1005, 2, 5, 1, DATE '2024-03-01');
INSERT INTO obj_user.orders (order_id, customer_id, product_id, qty, order_date) VALUES (1006, 4, 1, 1, DATE '2024-03-15');
INSERT INTO obj_user.orders (order_id, customer_id, product_id, qty, order_date) VALUES (1007, 1, 6, 2, DATE '2024-04-01');
INSERT INTO obj_user.orders (order_id, customer_id, product_id, qty, order_date) VALUES (1008, 3, 2, 5, DATE '2024-04-10');
COMMIT;

PROMPT
PROMPT === 作成結果の確認 ===
PROMPT

SET LINESIZE 80
COLUMN table_name FORMAT A15
COLUMN cnt        FORMAT 9,999

SELECT 'customers' table_name, COUNT(*) cnt FROM obj_user.customers
UNION ALL
SELECT 'products',              COUNT(*)     FROM obj_user.products
UNION ALL
SELECT 'orders',                COUNT(*)     FROM obj_user.orders;

PROMPT
PROMPT === セットアップ完了 ===
PROMPT 次のコマンドで obj_user に接続できます:
PROMPT   sqlplus obj_user/ObjUser#1@localhost:1521/xepdb1
PROMPT

EXIT;
