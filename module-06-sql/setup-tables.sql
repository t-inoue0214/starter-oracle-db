-- Module 6 実習: サンプルスキーマとデータの一括作成
-- 使用方法: sqlplus / as sysdba @/workspaces/starter-oracle-db/module-06-sql/setup-tables.sql

SET FEEDBACK ON
SET ECHO ON

-- PDB（XEPDB1）に切り替える
ALTER SESSION SET CONTAINER = XEPDB1;

PROMPT
PROMPT === 既存リソースのクリーンアップ ===
PROMPT

BEGIN
  EXECUTE IMMEDIATE 'DROP USER sql_user CASCADE';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

PROMPT
PROMPT === sql_user の作成 ===
PROMPT

CREATE USER sql_user IDENTIFIED BY SqlUser#1
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA 100M ON users;

GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE TO sql_user;

PROMPT
PROMPT === テーブルの作成 ===
PROMPT

-- 部門テーブル
CREATE TABLE sql_user.departments (
  dept_id   NUMBER(5)    PRIMARY KEY,
  dept_name VARCHAR2(30) NOT NULL,
  location  VARCHAR2(30)
);

-- 社員テーブル（dept_id=NULL と salary=NULL を含む）
CREATE TABLE sql_user.employees (
  emp_id    NUMBER(5)    PRIMARY KEY,
  name      VARCHAR2(50) NOT NULL,
  dept_id   NUMBER(5)    REFERENCES sql_user.departments(dept_id),
  salary    NUMBER(8,2),
  hire_date DATE         NOT NULL,
  job_title VARCHAR2(30)
);

-- 商品テーブル
CREATE TABLE sql_user.products (
  product_id NUMBER(5)     PRIMARY KEY,
  name       VARCHAR2(50)  NOT NULL,
  category   VARCHAR2(20),
  price      NUMBER(10,2)  NOT NULL
);

-- 注文テーブル
CREATE TABLE sql_user.orders (
  order_id   NUMBER(10)   PRIMARY KEY,
  emp_id     NUMBER(5)    REFERENCES sql_user.employees(emp_id),
  product_id NUMBER(5)    REFERENCES sql_user.products(product_id),
  quantity   NUMBER(5)    DEFAULT 1,
  order_date DATE         DEFAULT SYSDATE
);

PROMPT
PROMPT === サンプルデータの投入 ===
PROMPT

-- departments
INSERT INTO sql_user.departments VALUES (10, 'Engineering', 'Tokyo');
INSERT INTO sql_user.departments VALUES (20, 'Marketing',   'Osaka');
INSERT INTO sql_user.departments VALUES (30, 'HR',          'Tokyo');
INSERT INTO sql_user.departments VALUES (40, 'Finance',     'Nagoya');
COMMIT;

-- employees（dept_id=NULL の社員が2名、salary=NULL の社員が1名）
INSERT INTO sql_user.employees VALUES (1,  'Alice',   10, 5000, DATE '2021-04-01', 'Engineer');
INSERT INTO sql_user.employees VALUES (2,  'Bob',     20, 4200, DATE '2020-07-15', 'Marketer');
INSERT INTO sql_user.employees VALUES (3,  'Carol',   10, 5500, DATE '2019-10-01', 'Senior Engineer');
INSERT INTO sql_user.employees VALUES (4,  'Dave',    30, 3800, DATE '2022-01-10', 'HR Specialist');
INSERT INTO sql_user.employees VALUES (5,  'Eve',     20, 4600, DATE '2021-09-01', 'Marketer');
INSERT INTO sql_user.employees VALUES (6,  'Frank',   10, 6200, DATE '2018-04-01', 'Lead Engineer');
INSERT INTO sql_user.employees VALUES (7,  'Grace',   30, 3900, DATE '2023-04-01', 'HR Specialist');
INSERT INTO sql_user.employees VALUES (8,  'Hideo',   20, 4800, DATE '2020-11-01', 'Marketer');
INSERT INTO sql_user.employees VALUES (9,  'Iris',    NULL, NULL, DATE '2024-04-01', 'Intern');
INSERT INTO sql_user.employees VALUES (10, 'Jack',    NULL, 3500, DATE '2024-01-15', 'Contractor');
COMMIT;

-- products
INSERT INTO sql_user.products VALUES (1, 'Laptop',    'Electronics', 120000);
INSERT INTO sql_user.products VALUES (2, 'Mouse',     'Electronics',   3500);
INSERT INTO sql_user.products VALUES (3, 'Keyboard',  'Electronics',   8000);
INSERT INTO sql_user.products VALUES (4, 'Desk',      'Furniture',    45000);
INSERT INTO sql_user.products VALUES (5, 'Chair',     'Furniture',    35000);
INSERT INTO sql_user.products VALUES (6, 'Monitor',   'Electronics',  55000);
COMMIT;

-- orders
INSERT INTO sql_user.orders VALUES (1001, 1, 1, 1, DATE '2024-01-10');
INSERT INTO sql_user.orders VALUES (1002, 2, 2, 3, DATE '2024-01-15');
INSERT INTO sql_user.orders VALUES (1003, 1, 3, 1, DATE '2024-02-01');
INSERT INTO sql_user.orders VALUES (1004, 3, 6, 2, DATE '2024-02-10');
INSERT INTO sql_user.orders VALUES (1005, 5, 2, 5, DATE '2024-03-01');
INSERT INTO sql_user.orders VALUES (1006, 6, 4, 1, DATE '2024-03-15');
INSERT INTO sql_user.orders VALUES (1007, 2, 5, 1, DATE '2024-04-01');
INSERT INTO sql_user.orders VALUES (1008, 8, 1, 1, DATE '2024-04-10');
COMMIT;

PROMPT
PROMPT === 作成結果の確認 ===
PROMPT

SET LINESIZE 80
COLUMN table_name FORMAT A15
COLUMN cnt        FORMAT 9,999

SELECT 'departments' table_name, COUNT(*) cnt FROM sql_user.departments
UNION ALL
SELECT 'employees',              COUNT(*)     FROM sql_user.employees
UNION ALL
SELECT 'products',               COUNT(*)     FROM sql_user.products
UNION ALL
SELECT 'orders',                 COUNT(*)     FROM sql_user.orders;

PROMPT
PROMPT === セットアップ完了 ===
PROMPT 次のコマンドで sql_user に接続できます:
PROMPT   sqlplus sql_user/SqlUser#1@localhost:1521/xepdb1
PROMPT

EXIT;
