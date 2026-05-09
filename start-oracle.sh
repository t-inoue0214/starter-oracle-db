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

echo ""
echo "=== EM Express (tcps) 確認 ==="
HTTPS_PORT=$($ORACLE_HOME/bin/sqlplus -S / as sysdba <<'EOF'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT dbms_xdb_config.gethttpsport() FROM dual;
EXIT;
EOF
)
HTTPS_PORT=$(echo "$HTTPS_PORT" | tr -d '[:space:]')

if [ "$HTTPS_PORT" != "5500" ]; then
    echo "tcps ポートを 5500 に設定中..."
    $ORACLE_HOME/bin/sqlplus -S / as sysdba <<'EOF'
EXEC DBMS_XDB_CONFIG.SETHTTPPORT(0);
EXEC DBMS_XDB_CONFIG.SETHTTPSPORT(5500);
EXIT;
EOF
fi
echo "EM Express: tcps (HTTPS) ポート 5500 で動作中。"

echo ""
echo "=== EM Express ブラウザアクセス用プロキシ確認 ==="
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if ss -tlnp | grep -q "0.0.0.0:5501"; then
    echo "nginx はすでに起動しています（ポート 5501）。"
else
    CONF="$SCRIPT_DIR/nginx-em.conf"
    if [ ! -f "$CONF" ]; then
        echo "ERROR: $CONF が見つかりません。" >&2
        exit 1
    fi
    mkdir -p /tmp/nginx-logs
    sudo nginx -c "$CONF" -g "pid /tmp/nginx-em.pid;"
    sleep 1
    if ss -tlnp | grep -q "0.0.0.0:5501"; then
        echo "nginx を起動しました（ポート 5501）。"
    else
        echo "ERROR: nginx の起動に失敗しました。" >&2
        exit 1
    fi
fi
echo "EM Express アクセス URL: Codespaces のポート 5501 転送 URL + /em"
echo "  ユーザー名: SYSTEM（または SYS、ロール: SYSDBA）"
echo "  パスワード: インストール時に設定したパスワード（例: Oracle_21c）"
