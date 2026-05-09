#!/bin/bash
# Oracle Database 21c XE 起動スクリプト
# Codespaces 再起動後に実行してください
#
# 使用方法: bash start-oracle.sh

set -e

ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
ORACLE_SID=XE
export ORACLE_HOME ORACLE_SID

echo "=== Oracle XE 状態確認 ==="
STATUS_OUTPUT=$(sudo /etc/init.d/oracle-xe-21c status 2>&1)
echo "$STATUS_OUTPUT"

LISTENER_RUNNING=$(echo "$STATUS_OUTPUT" | grep "LISTENER status:" | grep -c "RUNNING" || true)
DB_RUNNING=$(echo "$STATUS_OUTPUT" | grep "XE Database status:" | grep -c "RUNNING" || true)

echo ""
if [ "$LISTENER_RUNNING" -eq 1 ] && [ "$DB_RUNNING" -eq 1 ]; then
    echo "Oracle XE はすでに起動しています。"
else
    echo "=== Oracle XE 起動中（約45秒かかります）==="
    sudo /etc/init.d/oracle-xe-21c start
    echo ""
    echo "=== 起動後の状態 ==="
    sudo /etc/init.d/oracle-xe-21c status
fi

echo ""
echo "=== インスタンス状態確認 ==="
INSTANCE_STATUS=$($ORACLE_HOME/bin/sqlplus -S / as sysdba <<'EOF'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT status FROM v$instance;
EXIT;
EOF
)

echo "v\$instance.status: $(echo $INSTANCE_STATUS | tr -d ' ')"

if echo "$INSTANCE_STATUS" | grep -q "OPEN"; then
    echo ""
    echo "Oracle Database は OPEN 状態です。学習を開始できます。"
else
    echo ""
    echo "インスタンスが OPEN になっていません。以下を確認してください:"
    echo "  sudo /etc/init.d/oracle-xe-21c status"
    exit 1
fi
