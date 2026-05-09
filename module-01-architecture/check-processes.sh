#!/bin/bash
# バックグラウンドプロセスと SGA 情報を確認するスクリプト

# Oracle 環境変数を読み込む
# shellcheck source=/etc/profile.d/oracle-env.sh
[ -f /etc/profile.d/oracle-env.sh ] && source /etc/profile.d/oracle-env.sh

echo "=== Oracle バックグラウンドプロセス ==="
ps aux | grep -E 'xe_' | grep -v grep

echo ""
echo "=== SGA 情報 ==="
sqlplus -s / as sysdba <<'EOF'
SET LINESIZE 60
COLUMN name FORMAT A32
COLUMN mb   FORMAT 9999.9
SELECT name, ROUND(bytes/1024/1024, 1) AS mb
FROM   v$sgainfo
ORDER BY bytes DESC;
EXIT
EOF
