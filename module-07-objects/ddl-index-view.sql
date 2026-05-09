-- Module 7 実習: DDL操作・索引・EXPLAIN PLAN・ビューのサンプル
-- 使用方法: sqlplus obj_user/ObjUser#1@localhost:1521/xepdb1 @/workspaces/starter-oracle-db/module-07-objects/ddl-index-view.sql
--
-- 前提: setup-schema.sql が完了していること

SET FEEDBACK ON
SET ECHO ON
SET LINESIZE 120
SET PAGESIZE 50

COLUMN name       FORMAT A20
COLUMN email      FORMAT A30
COLUMN category   FORMAT A15
COLUMN price      FORMAT 999,990

PROMPT
PROMPT === Step 2: ALTER TABLE（列の追加・変更・削除） ===
PROMPT

-- customers テーブルに phone 列を追加する
ALTER TABLE customers ADD (phone VARCHAR2(20));

-- 追加後の構造を確認する
DESCRIBE customers

-- phone 列を VARCHAR2(30) に拡張する
ALTER TABLE customers MODIFY (phone VARCHAR2(30));

-- phone 列を削除する
ALTER TABLE customers DROP COLUMN phone;

-- 削除後の構造を確認する
DESCRIBE customers

PROMPT
PROMPT === Step 3: DROP TABLE と RECYCLEBIN ===
PROMPT

-- テスト用テーブルを作成する
CREATE TABLE temp_test (id NUMBER, memo VARCHAR2(50));
INSERT INTO temp_test VALUES (1, 'RECYCLEBIN テスト行');
COMMIT;

-- DROP TABLE（デフォルトで RECYCLEBIN に移動する）
DROP TABLE temp_test;

-- RECYCLEBIN を確認する（BIN$ から始まる名前が表示される）
SHOW RECYCLEBIN

-- FLASHBACK TABLE で DROP 前の状態に復元する
FLASHBACK TABLE temp_test TO BEFORE DROP;

-- 復元後の確認
SELECT * FROM temp_test;

-- PURGE で RECYCLEBIN から完全削除する（復元不可）
DROP TABLE temp_test PURGE;

PROMPT  → SHOW RECYCLEBIN に temp_test が表示されなければ PURGE 完了

PROMPT
PROMPT === Step 4: 索引と EXPLAIN PLAN ===
PROMPT

-- 索引なしの実行計画を確認する
-- TABLE ACCESS FULL（全行スキャン）が表示される
EXPLAIN PLAN FOR
  SELECT product_id, name, price FROM products WHERE category = 'Electronics';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- B-tree索引を作成する
CREATE INDEX idx_products_category ON products(category);

-- 索引ありの実行計画を確認する
-- ※ 件数が少ない場合はオプティマイザが FULL スキャンを選ぶ場合がある
--   ヒント /*+ INDEX(...) */ で索引使用を強制する
EXPLAIN PLAN FOR
  SELECT /*+ INDEX(products idx_products_category) */ product_id, name, price
  FROM products WHERE category = 'Electronics';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- 関数ベース索引の作成例: UPPER(name) に索引を付ける
CREATE INDEX idx_customers_upper_name ON customers(UPPER(name));

-- 関数ベース索引が使われる実行計画を確認する
EXPLAIN PLAN FOR
  SELECT customer_id, name FROM customers WHERE UPPER(name) = 'ALICE';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- ユーザーが持つ索引を確認する
COLUMN index_name  FORMAT A30
COLUMN table_name  FORMAT A15
COLUMN column_name FORMAT A25

SELECT ic.index_name, ic.table_name, ic.column_name, i.index_type
FROM user_ind_columns ic
JOIN user_indexes i ON ic.index_name = i.index_name
WHERE ic.table_name IN ('PRODUCTS', 'CUSTOMERS')
ORDER BY ic.table_name, ic.index_name;

PROMPT
PROMPT === Step 5: ビュー ===
PROMPT

-- 注文サマリービューを作成する（customers・products・orders を結合）
CREATE OR REPLACE VIEW v_order_summary AS
SELECT o.order_id,
       c.name          customer_name,
       p.name          product_name,
       p.category,
       o.qty,
       o.qty * p.price total_price,
       o.order_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products  p ON o.product_id  = p.product_id;

-- ビューから SELECT する
COLUMN customer_name FORMAT A15
COLUMN product_name  FORMAT A15
COLUMN total_price   FORMAT 9,999,990

SELECT order_id, customer_name, product_name, total_price
FROM v_order_summary
ORDER BY order_date;

-- WITH READ ONLY ビュー: Electronics カテゴリのみを表示する読み取り専用ビュー
CREATE OR REPLACE VIEW v_products_electronics AS
SELECT product_id, name, price
FROM products
WHERE category = 'Electronics'
WITH READ ONLY;

-- SELECT は成功する
SELECT * FROM v_products_electronics;

-- UPDATE は ORA-42399 で失敗する（WHENEVER SQLERROR CONTINUE で続行する）
WHENEVER SQLERROR CONTINUE
UPDATE v_products_electronics SET price = 99999 WHERE product_id = 1;
WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT  → ORA-42399 が発生すれば WITH READ ONLY が有効

EXIT;
