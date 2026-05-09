-- Module 4 実習: データファイル管理・セグメント確認・HWM 観察
-- 使用方法: sqlplus / as sysdba @/workspaces/starter-oracle-db/module-04-storage/manage-datafiles.sql
--
-- 前提: create-tablespace.sql が完了していること（app_data 表領域が存在すること）

SET FEEDBACK ON
SET ECHO ON
SET LINESIZE 150
SET PAGESIZE 50

-- PDB（XEPDB1）に切り替える
ALTER SESSION SET CONTAINER = XEPDB1;

PROMPT
PROMPT === Step 3: データファイルの追加とリサイズ ===
PROMPT

-- app_data にデータファイルを追加する
ALTER TABLESPACE app_data
  ADD DATAFILE '/opt/oracle/oradata/XE/XEPDB1/app_data02.dbf' SIZE 10M;

-- 既存のデータファイルをリサイズする
ALTER DATABASE DATAFILE '/opt/oracle/oradata/XE/XEPDB1/app_data01.dbf'
  RESIZE 20M;

PROMPT
PROMPT === 変更後のデータファイル一覧 ===
PROMPT

COLUMN file_name FORMAT A65
COLUMN mb        FORMAT 9,990.0

SELECT file_name, ROUND(bytes/1024/1024, 0) mb, autoextensible
FROM dba_data_files
WHERE tablespace_name = 'APP_DATA'
ORDER BY file_id;

PROMPT
PROMPT === Step 6: テスト用テーブルの作成と行挿入 ===
PROMPT

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE storage_test PURGE';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE storage_test (
  id     NUMBER,
  data   VARCHAR2(100)
) TABLESPACE app_data;

-- 1000 行挿入してセグメントを成長させる
BEGIN
  FOR i IN 1..1000 LOOP
    INSERT INTO storage_test VALUES (i, LPAD('X', 100, 'X'));
  END LOOP;
  COMMIT;
END;
/

PROMPT
PROMPT === セグメントの使用状況（1000 行挿入後） ===
PROMPT

COLUMN segment_name FORMAT A20
COLUMN segment_type FORMAT A12
COLUMN extents      FORMAT 9,999   HEADING 'エクステント数'
COLUMN blocks       FORMAT 9,999   HEADING 'ブロック数'
COLUMN kb           FORMAT 9,990   HEADING '使用(KB)'

SELECT segment_name, segment_type, extents, blocks,
       ROUND(bytes/1024, 0) kb
FROM dba_segments
WHERE owner = 'SYS' AND segment_name = 'STORAGE_TEST';

PROMPT
PROMPT === エクステントの内訳 ===
PROMPT

COLUMN extent_id FORMAT 999     HEADING 'エクステントID'
COLUMN block_id  FORMAT 9,999   HEADING '開始ブロック'
COLUMN blocks    FORMAT 9,999   HEADING 'ブロック数'

SELECT extent_id, block_id, blocks
FROM dba_extents
WHERE owner = 'SYS' AND segment_name = 'STORAGE_TEST'
ORDER BY extent_id;

PROMPT
PROMPT === Step 7: HWM の観察 — DELETE 後（HWM は変わらない） ===
PROMPT

DELETE FROM storage_test;
COMMIT;

SELECT extents, blocks, ROUND(bytes/1024, 0) kb
FROM dba_segments
WHERE owner = 'SYS' AND segment_name = 'STORAGE_TEST';

PROMPT  DELETE 後もセグメントサイズは変わっていない（HWM が残っている）。
PROMPT

PROMPT === 1000 行を再挿入する ===
PROMPT

BEGIN
  FOR i IN 1..1000 LOOP
    INSERT INTO storage_test VALUES (i, LPAD('X', 100, 'X'));
  END LOOP;
  COMMIT;
END;
/

PROMPT
PROMPT === TRUNCATE 後（HWM がリセットされる） ===
PROMPT

TRUNCATE TABLE storage_test;

SELECT extents, blocks, ROUND(bytes/1024, 0) kb
FROM dba_segments
WHERE owner = 'SYS' AND segment_name = 'STORAGE_TEST';

PROMPT  TRUNCATE 後はブロック数が大幅に減少している（HWM がリセットされた）。
PROMPT

PROMPT
PROMPT === Step 8: データブロックのパラメータ ===
PROMPT

COLUMN name  FORMAT A40
COLUMN value FORMAT A20

SELECT name, value FROM v$parameter
WHERE name IN ('db_block_size', 'db_file_multiblock_read_count');

PROMPT
PROMPT === テーブル統計情報の収集と確認 ===
PROMPT

EXEC DBMS_STATS.GATHER_TABLE_STATS('SYS', 'STORAGE_TEST');

COLUMN table_name   FORMAT A20
COLUMN num_rows     FORMAT 9,999,999
COLUMN blocks       FORMAT 9,999
COLUMN avg_row_len  FORMAT 9,999

SELECT table_name, num_rows, blocks, avg_row_len
FROM dba_tables
WHERE owner = 'SYS' AND table_name = 'STORAGE_TEST';

PROMPT
PROMPT === クリーンアップ ===
PROMPT

DROP TABLE storage_test PURGE;
DROP TABLESPACE app_omf INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE app_data INCLUDING CONTENTS AND DATAFILES;

-- OMF 設定を元に戻す
ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER SYSTEM SET DB_CREATE_FILE_DEST='' SCOPE=BOTH;

PROMPT
PROMPT === 完了 ===
PROMPT storage_test テーブル・app_data・app_omf を削除しました。
PROMPT

EXIT;
