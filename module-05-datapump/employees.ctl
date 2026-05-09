-- SQL*Loader コントロールファイル
-- ロード先テーブル: emp_load（dp_target スキーマ）
-- 使用方法:
--   sqlldr dp_target/DpTarget#1@localhost:1521/xepdb1 \
--     control=/workspaces/starter-oracle-db/module-05-datapump/employees.ctl \
--     log=/workspaces/starter-oracle-db/module-05-datapump/sqlldr.log \
--     bad=/workspaces/starter-oracle-db/module-05-datapump/sqlldr.bad

OPTIONS (SKIP=1)
LOAD DATA
INFILE '/workspaces/starter-oracle-db/module-05-datapump/employees.csv'
INTO TABLE emp_load TRUNCATE
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
  id,
  name,
  department,
  salary
)
