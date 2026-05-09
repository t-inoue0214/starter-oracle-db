-- Module 4 実習: 表領域の作成と OMF 動作確認
-- 使用方法: sqlplus / as sysdba @/workspaces/starter-oracle-db/module-04-storage/create-tablespace.sql

SET FEEDBACK ON
SET ECHO ON
SET LINESIZE 150
SET PAGESIZE 50

-- CDB ルートで OMF を有効にする
ALTER SYSTEM SET DB_CREATE_FILE_DEST='/opt/oracle/oradata/XE' SCOPE=BOTH;

-- PDB（XEPDB1）に切り替える
ALTER SESSION SET CONTAINER = XEPDB1;

PROMPT
PROMPT === 既存リソースのクリーンアップ ===
PROMPT

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLESPACE app_omf INCLUDING CONTENTS AND DATAFILES';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLESPACE app_data INCLUDING CONTENTS AND DATAFILES';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

PROMPT
PROMPT === DATAFILE 指定で表領域を作成する ===
PROMPT

CREATE TABLESPACE app_data
  DATAFILE '/opt/oracle/oradata/XE/XEPDB1/app_data01.dbf' SIZE 10M
  AUTOEXTEND ON NEXT 5M MAXSIZE 100M
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE
  SEGMENT SPACE MANAGEMENT AUTO;

PROMPT
PROMPT === 作成確認: dba_tablespaces ===
PROMPT

COLUMN tablespace_name FORMAT A20
COLUMN status          FORMAT A10
COLUMN contents        FORMAT A11
COLUMN extent_management FORMAT A16
COLUMN segment_space_management FORMAT A10

SELECT tablespace_name, status, contents, extent_management, segment_space_management
FROM dba_tablespaces
WHERE tablespace_name = 'APP_DATA';

PROMPT
PROMPT === 作成確認: dba_data_files ===
PROMPT

COLUMN file_name FORMAT A70
COLUMN mb        FORMAT 9,990.0
COLUMN maxmb     FORMAT 9,990.0

SELECT file_name,
       ROUND(bytes/1024/1024, 0) mb,
       autoextensible,
       ROUND(maxbytes/1024/1024, 0) maxmb
FROM dba_data_files
WHERE tablespace_name = 'APP_DATA';

PROMPT
PROMPT === OMF で表領域を作成する（DATAFILE 句を省略） ===
PROMPT

CREATE TABLESPACE app_omf;

PROMPT
PROMPT === OMF 表領域の確認（Oracle が自動生成したファイル名） ===
PROMPT

SELECT file_name, ROUND(bytes/1024/1024, 0) mb
FROM dba_data_files
WHERE tablespace_name = 'APP_OMF';

PROMPT
PROMPT === 全 PERMANENT 表領域の空き容量サマリ ===
PROMPT

COLUMN total_mb    FORMAT 9,990.0  HEADING '合計(MB)'
COLUMN free_mb     FORMAT 9,990.0  HEADING '空き(MB)'
COLUMN used_pct    FORMAT 990.0    HEADING '使用率(%)'

SELECT
  t.tablespace_name,
  ROUND(SUM(d.bytes)/1024/1024, 1)             total_mb,
  ROUND(SUM(NVL(f.free_bytes,0))/1024/1024, 1) free_mb,
  ROUND((1 - SUM(NVL(f.free_bytes,0))
              / SUM(d.bytes)) * 100, 1)         used_pct
FROM dba_tablespaces t
JOIN dba_data_files d ON t.tablespace_name = d.tablespace_name
LEFT JOIN (
  SELECT tablespace_name, SUM(bytes) free_bytes
  FROM   dba_free_space
  GROUP  BY tablespace_name
) f ON t.tablespace_name = f.tablespace_name
WHERE t.contents = 'PERMANENT'
GROUP BY t.tablespace_name
ORDER BY t.tablespace_name;

PROMPT
PROMPT === セットアップ完了 ===
PROMPT app_data と app_omf が作成されました。
PROMPT manage-datafiles.sql でデータファイルの追加・リサイズ・セグメント確認を行えます。
PROMPT

EXIT;
