-- Module 2 実習: 主要初期化パラメータの確認
-- 使用方法: sqlplus / as sysdba @/workspaces/starter-oracle-db/module-02-instance/check-params.sql

SET PAGESIZE 30
SET LINESIZE 120
SET FEEDBACK OFF
COLUMN name        FORMAT A35
COLUMN value       FORMAT A55
COLUMN description FORMAT A55

PROMPT
PROMPT === 主要初期化パラメータ一覧 ===
PROMPT

SELECT
    name,
    value,
    description
FROM v$parameter
WHERE name IN (
    'db_name',
    'db_block_size',
    'sga_target',
    'pga_aggregate_target',
    'processes',
    'sessions',
    'open_cursors',
    'control_files',
    'undo_management',
    'enable_pluggable_database'
)
ORDER BY name;

PROMPT
PROMPT === SPFILE 使用確認 ===
PROMPT

SELECT
    CASE
        WHEN value IS NOT NULL THEN '使用中: ' || value
        ELSE 'PFILE を使用中（SPFILE なし）'
    END AS spfile_status
FROM v$parameter
WHERE name = 'spfile';

PROMPT
PROMPT === 動的パラメータ（SCOPE=BOTH で変更可能）の例 ===
PROMPT

SELECT name, value, issys_modifiable
FROM v$parameter
WHERE name IN ('sessions', 'open_cursors', 'pga_aggregate_target')
ORDER BY name;

EXIT;
