-- Module 3 実習: 学習用ユーザーの一括セットアップ
-- 使用方法: sqlplus / as sysdba @/workspaces/starter-oracle-db/module-03-security/create-users.sql
--
-- Oracle 21c XE はマルチテナント（CDB/PDB）構成のため、
-- ローカルユーザーは PDB（XEPDB1）で作成します。
--
-- 作成するユーザー:
--   app_user      ... アプリケーション用（CREATE TABLE / INSERT / UPDATE 可）
--   readonly_user ... 参照専用（接続のみ）

SET FEEDBACK ON
SET ECHO ON

-- PDB（XEPDB1）に切り替える
ALTER SESSION SET CONTAINER = XEPDB1;

PROMPT
PROMPT === 既存ユーザーのクリーンアップ ===
PROMPT

BEGIN
  EXECUTE IMMEDIATE 'DROP USER readonly_user CASCADE';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP USER app_user CASCADE';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP PROFILE app_profile';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

PROMPT
PROMPT === ユーザーの作成 ===
PROMPT

-- アプリケーション用ユーザー
CREATE USER app_user IDENTIFIED BY AppUser#1
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA 100M ON users;

-- 参照専用ユーザー（QUOTA 0: オブジェクト作成不可）
CREATE USER readonly_user IDENTIFIED BY ReadOnly#1
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA 0 ON users;

PROMPT
PROMPT === 権限・ロールの付与 ===
PROMPT

-- 接続権限（必須）
GRANT CREATE SESSION TO app_user;
GRANT CREATE SESSION TO readonly_user;

-- RESOURCE ロール: CREATE TABLE / CREATE SEQUENCE / CREATE PROCEDURE など
GRANT RESOURCE TO app_user;

PROMPT
PROMPT === 作成結果の確認 ===
PROMPT

SET LINESIZE 120
COLUMN username FORMAT A20
COLUMN account_status FORMAT A20
COLUMN default_tablespace FORMAT A15
COLUMN profile FORMAT A15

SELECT username, account_status, default_tablespace, profile
FROM dba_users
WHERE username IN ('APP_USER', 'READONLY_USER')
ORDER BY username;

PROMPT
PROMPT === APP_USER に付与された権限 ===
PROMPT

SELECT grantee, privilege FROM dba_sys_privs WHERE grantee = 'APP_USER';
SELECT grantee, granted_role FROM dba_role_privs WHERE grantee = 'APP_USER';

PROMPT
PROMPT === セットアップ完了 ===
PROMPT
PROMPT 次のコマンドで app_user に接続できます:
PROMPT   sqlplus app_user/AppUser#1@localhost:1521/xepdb1
PROMPT

EXIT;
