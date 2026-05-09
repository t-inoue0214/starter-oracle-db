-- Module 5 実習: 外部表の作成・参照・クリーンアップ
-- 使用方法: sqlplus / as sysdba @/workspaces/starter-oracle-db/module-05-datapump/external-table.sql
--
-- 前提: MODULE05_DIR ディレクトリオブジェクトが作成済みであること（Step 1 で作成）
--       employees.csv が module-05-datapump/ に存在すること

SET FEEDBACK ON
SET ECHO ON
SET LINESIZE 100
SET PAGESIZE 50

-- PDB（XEPDB1）に切り替える（MODULE05_DIR はここで作成済み）
ALTER SESSION SET CONTAINER = XEPDB1;

PROMPT
PROMPT === 既存の外部表をクリーンアップ ===
PROMPT

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE sys.ext_employees';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

PROMPT
PROMPT === 外部表の作成（employees.csv を参照） ===
PROMPT

CREATE TABLE sys.ext_employees (
  id         NUMBER,
  name       VARCHAR2(50),
  department VARCHAR2(30),
  salary     NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE oracle_loader
  DEFAULT DIRECTORY module05_dir
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    SKIP 1
    FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
  )
  LOCATION ('employees.csv')
)
REJECT LIMIT UNLIMITED;

PROMPT
PROMPT === SELECT で CSV の内容を参照する ===
PROMPT

COLUMN name       FORMAT A15
COLUMN department FORMAT A15
COLUMN salary     FORMAT 9,999

SELECT id, name, department, salary
FROM sys.ext_employees
ORDER BY id;

PROMPT
PROMPT  ↑ Oracle にデータは保存されていない。SELECT のたびに employees.csv を読み込んでいる。
PROMPT

PROMPT
PROMPT === 外部表の定義を確認する ===
PROMPT

COLUMN table_name            FORMAT A20
COLUMN type_name             FORMAT A15
COLUMN default_directory_name FORMAT A20

SELECT table_name, type_name, default_directory_name
FROM dba_external_tables
WHERE owner = 'SYS' AND table_name = 'EXT_EMPLOYEES';

PROMPT
PROMPT === クリーンアップ ===
PROMPT

DROP TABLE sys.ext_employees;

PROMPT
PROMPT  外部表を削除しました。employees.csv ファイルは残っています。
PROMPT

EXIT;
