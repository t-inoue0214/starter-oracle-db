-- Module 7 実習: 制約違反デモ・ENABLE/DISABLE・シーケンスのサンプル
-- 使用方法: sqlplus obj_user/ObjUser#1@localhost:1521/xepdb1 @/workspaces/starter-oracle-db/module-07-objects/constraint-sequence-demo.sql
--
-- 前提: setup-schema.sql が完了していること

SET FEEDBACK ON
SET ECHO ON
SET LINESIZE 120
SET PAGESIZE 50

-- エラー時も続行する（制約違反を意図的に確認するため）
WHENEVER SQLERROR CONTINUE

COLUMN constraint_name FORMAT A25
COLUMN table_name      FORMAT A15
COLUMN status          FORMAT A10

PROMPT
PROMPT === Step 7-1: NOT NULL 制約違反（ORA-01400） ===
PROMPT

-- name=NULL で INSERT する（nn_customers_name 制約で ORA-01400 が発生する）
INSERT INTO customers (customer_id, name, email) VALUES (99, NULL, 'test@example.com');

PROMPT  → ORA-01400 が発生すれば NOT NULL 制約が有効
PROMPT

PROMPT
PROMPT === Step 7-2: PRIMARY KEY 制約違反（ORA-00001） ===
PROMPT

-- customer_id=1 はすでに存在する（pk_customers 制約で ORA-00001 が発生する）
INSERT INTO customers (customer_id, name, email) VALUES (1, 'Duplicate Alice', 'dup@example.com');

PROMPT  → ORA-00001 が発生すれば PRIMARY KEY 制約が有効
PROMPT

PROMPT
PROMPT === Step 7-3: FOREIGN KEY 制約違反（ORA-02291） ===
PROMPT

-- customer_id=999 は customers テーブルに存在しない（fk_orders_customer 制約で ORA-02291 が発生する）
INSERT INTO orders (order_id, customer_id, product_id, qty) VALUES (9001, 999, 1, 1);

PROMPT  → ORA-02291 が発生すれば FOREIGN KEY 制約が有効
PROMPT

PROMPT
PROMPT === Step 7-4: CHECK 制約違反（ORA-02290） ===
PROMPT

-- price=-1 は CHECK(price > 0) に違反する（chk_products_price 制約で ORA-02290 が発生する）
INSERT INTO products (product_id, name, category, price) VALUES (99, 'Invalid', 'Test', -1);

PROMPT  → ORA-02290 が発生すれば CHECK 制約が有効
PROMPT

PROMPT
PROMPT === Step 7-5: DISABLE / ENABLE CONSTRAINT ===
PROMPT

-- 現在の制約の状態を確認する
SELECT constraint_name, table_name, status
FROM user_constraints
WHERE table_name = 'ORDERS' AND constraint_name LIKE 'FK%';

-- FOREIGN KEY 制約を無効化する
ALTER TABLE orders DISABLE CONSTRAINT fk_orders_customer;

-- 無効化後は存在しない customer_id でも INSERT できる
INSERT INTO orders (order_id, customer_id, product_id, qty) VALUES (9002, 999, 1, 1);
COMMIT;

PROMPT  → 制約無効中は参照整合性を無視した INSERT が可能
PROMPT

-- ENABLE しようとすると ORA-02298（整合性違反データが残っている）でエラーになる
ALTER TABLE orders ENABLE CONSTRAINT fk_orders_customer;

PROMPT  → ORA-02298 が発生すれば、DISABLE 中に投入した矛盾データが原因
PROMPT

-- 矛盾データを削除してから ENABLE する
DELETE FROM orders WHERE order_id = 9002;
COMMIT;

ALTER TABLE orders ENABLE CONSTRAINT fk_orders_customer;

-- ENABLE 後の状態を確認する
SELECT constraint_name, table_name, status
FROM user_constraints
WHERE table_name = 'ORDERS' AND constraint_name LIKE 'FK%';

PROMPT  → STATUS が ENABLED に戻れば成功
PROMPT

-- 以降は通常のエラー処理に戻す
WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT
PROMPT === Step 7-6: シーケンス（SEQUENCE） ===
PROMPT

-- シーケンスを作成する（2001 からスタート、1 ずつ増加、キャッシュなし）
CREATE SEQUENCE seq_order_id
  START WITH 2001
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- NEXTVAL を使って連続した order_id で INSERT する
INSERT INTO orders (order_id, customer_id, product_id, qty)
VALUES (seq_order_id.NEXTVAL, 5, 3, 1);

INSERT INTO orders (order_id, customer_id, product_id, qty)
VALUES (seq_order_id.NEXTVAL, 5, 6, 2);

COMMIT;

-- 挿入結果を確認する
COLUMN order_id     FORMAT 9,999
COLUMN customer_id  FORMAT 9,999
COLUMN product_id   FORMAT 9,999

SELECT order_id, customer_id, product_id, qty FROM orders
WHERE order_id >= 2001
ORDER BY order_id;

-- シーケンスの現在値を確認する（最後に発行した NEXTVAL）
SELECT seq_order_id.CURRVAL FROM dual;

-- シーケンスの定義を確認する
COLUMN sequence_name FORMAT A20
COLUMN cycle_flag    FORMAT A6

SELECT sequence_name, min_value, max_value, increment_by, cache_size, cycle_flag
FROM user_sequences
WHERE sequence_name = 'SEQ_ORDER_ID';

EXIT;
