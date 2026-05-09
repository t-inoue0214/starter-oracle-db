-- Module 3 実習: カスタムロールとオブジェクト権限の付与
-- 使用方法: sqlplus / as sysdba @/workspaces/starter-oracle-db/module-03-security/grant-roles.sql
--
-- 前提: create-users.sql と Step 4 のテーブル作成（app_user.employees）が完了していること

SET FEEDBACK ON
SET ECHO ON

-- PDB（XEPDB1）に切り替える
ALTER SESSION SET CONTAINER = XEPDB1;

PROMPT
PROMPT === カスタムロールの作成 ===
PROMPT

BEGIN
  EXECUTE IMMEDIATE 'DROP ROLE app_readonly';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE ROLE app_readonly;

PROMPT
PROMPT === ロールへのオブジェクト権限付与 ===
PROMPT

GRANT SELECT ON app_user.employees TO app_readonly;

PROMPT
PROMPT === readonly_user へのロール付与 ===
PROMPT

GRANT app_readonly TO readonly_user;

PROMPT
PROMPT === 付与確認: システム権限 ===
PROMPT

SET LINESIZE 120
COLUMN grantee FORMAT A20
COLUMN privilege FORMAT A30
COLUMN granted_role FORMAT A20
COLUMN table_name FORMAT A20
COLUMN grantor FORMAT A20

SELECT grantee, privilege
FROM dba_sys_privs
WHERE grantee IN ('APP_USER', 'READONLY_USER', 'APP_READONLY')
ORDER BY grantee, privilege;

PROMPT
PROMPT === 付与確認: ロール ===
PROMPT

SELECT grantee, granted_role
FROM dba_role_privs
WHERE grantee IN ('APP_USER', 'READONLY_USER')
ORDER BY grantee;

PROMPT
PROMPT === 付与確認: オブジェクト権限（ロール経由） ===
PROMPT

SELECT grantee, owner, table_name, privilege
FROM dba_tab_privs
WHERE grantee = 'APP_READONLY';

PROMPT
PROMPT === REVOKE サンプル（必要に応じて実行） ===
PROMPT
PROMPT -- 権限を剥奪する場合:
PROMPT -- REVOKE app_readonly FROM readonly_user;
PROMPT -- DROP ROLE app_readonly;
PROMPT

EXIT;
