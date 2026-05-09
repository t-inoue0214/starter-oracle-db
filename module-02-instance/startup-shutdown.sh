#!/bin/bash
# Module 2 実習: STARTUP/SHUTDOWN の段階実演スクリプト
#
# 使用方法: bash /workspaces/starter-oracle-db/module-02-instance/startup-shutdown.sh
#
# このスクリプトは NOMOUNT → MOUNT → OPEN の各フェーズで停止しながら
# 参照できるビューの違いを確認します。実行するとデータベースが一時停止します。

ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
ORACLE_SID=XE
export ORACLE_HOME ORACLE_SID

SQLPLUS="$ORACLE_HOME/bin/sqlplus -s / as sysdba"

echo "=== Module 2: STARTUP/SHUTDOWN フェーズ実演 ==="
echo ""
echo "警告: このスクリプトはデータベースを一時停止します。"
echo "実行してよろしいですか？ [y/N]: "
read -r ANSWER
if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
    echo "キャンセルしました。"
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[現在の状態確認]"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$SQLPLUS <<'EOF'
SET PAGESIZE 20 LINESIZE 100
SELECT instance_name, status, database_status FROM v$instance;
EXIT;
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[1/4] SHUTDOWN IMMEDIATE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$ORACLE_HOME/bin/sqlplus / as sysdba <<'EOF'
SHUTDOWN IMMEDIATE;
EXIT;
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[2/4] STARTUP NOMOUNT"
echo "  → パラメータファイルのみ読み込む"
echo "  → SGA 確保・バックグラウンドプロセス起動"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$SQLPLUS <<'EOF'
STARTUP NOMOUNT;
EXIT;
EOF

echo ""
echo "--- NOMOUNT 中に参照できるビュー (v\$parameter) ---"
$SQLPLUS <<'EOF'
SET PAGESIZE 20 LINESIZE 100
COLUMN name FORMAT A30
COLUMN value FORMAT A50
SELECT name, value FROM v$parameter
WHERE name IN ('db_name', 'sga_target', 'processes')
ORDER BY name;
EXIT;
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[3/4] ALTER DATABASE MOUNT"
echo "  → 制御ファイルを読み込む"
echo "  → データファイル・REDO ログの場所を認識する"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$SQLPLUS <<'EOF'
ALTER DATABASE MOUNT;
EXIT;
EOF

echo ""
echo "--- MOUNT 中に参照できるビュー (v\$controlfile / v\$logfile) ---"
$SQLPLUS <<'EOF'
SET PAGESIZE 20 LINESIZE 100
COLUMN name FORMAT A60
COLUMN member FORMAT A60
SELECT name FROM v$controlfile;
SELECT group#, member FROM v$logfile ORDER BY group#;
EXIT;
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[4/4] ALTER DATABASE OPEN"
echo "  → データファイルの整合性を確認する"
echo "  → ユーザー接続が可能になる"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$SQLPLUS <<'EOF'
ALTER DATABASE OPEN;
EXIT;
EOF

echo ""
echo "--- OPEN 後の状態確認 ---"
$SQLPLUS <<'EOF'
SET PAGESIZE 20 LINESIZE 100
SELECT instance_name, status, database_status FROM v$instance;
EXIT;
EOF

echo ""
echo "=== 完了: データベースが OPEN になりました ==="
