-- Module 5 実習: ディレクトリオブジェクト作成・ソーススキーマ作成・サンプルデータ投入
-- 使用方法: sqlplus / as sysdba @/workspaces/starter-oracle-db/module-05-datapump/setup-source.sql

SET FEEDBACK ON
SET ECHO ON

-- PDB（XEPDB1）に切り替える
ALTER SESSION SET CONTAINER = XEPDB1;

PROMPT
PROMPT === ディレクトリオブジェクトの作成 ===
PROMPT

CREATE OR REPLACE DIRECTORY module05_dir
  AS '/workspaces/starter-oracle-db/module-05-datapump';

GRANT READ, WRITE ON DIRECTORY module05_dir TO system;

PROMPT
PROMPT === 既存リソースのクリーンアップ ===
PROMPT

BEGIN
  EXECUTE IMMEDIATE 'DROP USER dp_source CASCADE';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

PROMPT
PROMPT === dp_source ユーザーの作成 ===
PROMPT

CREATE USER dp_source IDENTIFIED BY DpSource#1
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA 100M ON users;

GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE TO dp_source;

PROMPT
PROMPT === テーブルとサンプルデータの作成 ===
PROMPT

-- departments テーブル
CREATE TABLE dp_source.departments (
  dept_id   NUMBER       PRIMARY KEY,
  dept_name VARCHAR2(30) NOT NULL
);

INSERT INTO dp_source.departments VALUES (10, 'Engineering');
INSERT INTO dp_source.departments VALUES (20, 'Marketing');
INSERT INTO dp_source.departments VALUES (30, 'HR');
COMMIT;

-- employees テーブル
CREATE TABLE dp_source.employees (
  id         NUMBER        PRIMARY KEY,
  name       VARCHAR2(50)  NOT NULL,
  dept_id    NUMBER        REFERENCES dp_source.departments(dept_id),
  salary     NUMBER
);

INSERT INTO dp_source.employees VALUES (1, 'Alice',  10, 5000);
INSERT INTO dp_source.employees VALUES (2, 'Bob',    20, 4200);
INSERT INTO dp_source.employees VALUES (3, 'Carol',  10, 5500);
INSERT INTO dp_source.employees VALUES (4, 'Dave',   30, 3800);
INSERT INTO dp_source.employees VALUES (5, 'Eve',    20, 4600);
INSERT INTO dp_source.employees VALUES (6, 'Frank',  10, 6000);
INSERT INTO dp_source.employees VALUES (7, 'Grace',  30, 3900);
INSERT INTO dp_source.employees VALUES (8, 'Hideo',  20, 4800);
COMMIT;

PROMPT
PROMPT === 作成結果の確認 ===
PROMPT

SET LINESIZE 80
COLUMN table_name   FORMAT A20
COLUMN num_rows     FORMAT 9,999

SELECT table_name FROM dba_tables WHERE owner = 'DP_SOURCE' ORDER BY table_name;

SELECT 'departments' table_name, COUNT(*) num_rows FROM dp_source.departments
UNION ALL
SELECT 'employees',              COUNT(*)           FROM dp_source.employees;

PROMPT
PROMPT === セットアップ完了 ===
PROMPT dp_source スキーマに departments（3行）と employees（8行）を作成しました。
PROMPT 次のコマンドで expdp を実行してください:
PROMPT   expdp system@localhost:1521/xepdb1 schemas=dp_source dumpfile=dp_source.dmp logfile=dp_export.log directory=MODULE05_DIR
PROMPT

EXIT;
