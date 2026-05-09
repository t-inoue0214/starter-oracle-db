-- Module 3 実習: UNDO 表領域の状態監視
-- 使用方法: sqlplus / as sysdba @/workspaces/starter-oracle-db/module-03-security/monitor-undo.sql

SET PAGESIZE 50
SET LINESIZE 120
SET FEEDBACK OFF

-- PDB（XEPDB1）に切り替える
ALTER SESSION SET CONTAINER = XEPDB1;

PROMPT
PROMPT === UNDO 関連パラメータ ===
PROMPT

COLUMN name  FORMAT A25
COLUMN value FORMAT A40

SELECT name, value FROM v$parameter
WHERE name IN ('undo_management', 'undo_retention', 'undo_tablespace')
ORDER BY name;

PROMPT
PROMPT === UNDO セグメントの状態（ACTIVE / UNEXPIRED / EXPIRED） ===
PROMPT

COLUMN status  FORMAT A12
COLUMN extents FORMAT 9,999
COLUMN mb      FORMAT 999,990.9

SELECT
  status,
  COUNT(*)                         extents,
  ROUND(SUM(bytes)/1024/1024, 1)   mb
FROM dba_undo_extents
GROUP BY status
ORDER BY status;

PROMPT
PROMPT  ACTIVE    ... 現在のトランザクションが使用中
PROMPT  UNEXPIRED ... コミット済みだが UNDO_RETENTION 期間内のため保持中
PROMPT  EXPIRED   ... UNDO_RETENTION を超えて再利用可能な状態
PROMPT

PROMPT
PROMPT === v$undostat: 直近5レコード（10 分間隔の UNDO 使用統計） ===
PROMPT

COLUMN begin_time          FORMAT A8
COLUMN end_time            FORMAT A8
COLUMN txncount            FORMAT 99,999   HEADING 'TX 数'
COLUMN maxconcurrency      FORMAT 999      HEADING '最大並列TX'
COLUMN ssolderrcnt         FORMAT 9,999    HEADING 'ORA-01555'
COLUMN tuned_undoretention FORMAT 999,999  HEADING 'チューニング保持(秒)'

SELECT
  TO_CHAR(begin_time, 'HH24:MI')  begin_time,
  TO_CHAR(end_time,   'HH24:MI')  end_time,
  txncount,
  maxconcurrency,
  ssolderrcnt,
  tuned_undoretention
FROM v$undostat
ORDER BY begin_time DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT
PROMPT  ORA-01555 列が 0 より大きい場合、スナップショットが古すぎるエラーが発生しています。
PROMPT  UNDO_RETENTION を増やすか、UNDO 表領域を拡張することを検討してください。
PROMPT

PROMPT
PROMPT === UNDO_RETENTION の変更サンプル（必要に応じて実行） ===
PROMPT

PROMPT -- UNDO_RETENTION を 1800 秒（30 分）に変更する:
PROMPT -- ALTER SYSTEM SET undo_retention = 1800 SCOPE=BOTH;
PROMPT

EXIT;
