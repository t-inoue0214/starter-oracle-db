#!/bin/bash
# Oracle Database 21c XE インストールスクリプト
# 実行前に oracle.com から RPM をダウンロードしてホームディレクトリに配置すること

set -e

# RPM ファイルの存在チェック（プロジェクトルートを確認）
RPM_FILE=$(ls /workspaces/starter-oracle-db/oracle-database-xe-21c-*.rpm 2>/dev/null | head -1)
if [ -z "$RPM_FILE" ]; then
    echo "エラー: oracle-database-xe-21c-*.rpm がプロジェクトルートに見つかりません。"
    echo "https://www.oracle.com/database/technologies/xe-downloads.html から"
    echo "RPM をダウンロードし、/workspaces/starter-oracle-db/ に配置してください。"
    exit 1
fi

echo "=== Step 1: Oracle Database 21c XE のインストール（$RPM_FILE）==="
sudo ORACLE_DOCKER_INSTALL=true dnf localinstall -y "$RPM_FILE"

echo ""
echo "=== Step 2: 初期データベースの設定（パスワード入力を求められます） ==="
sudo ORACLE_HOSTNAME=localhost /etc/init.d/oracle-xe-21c configure

echo ""
echo "=== Step 3: 環境変数の読み込み ==="
source /etc/profile.d/oracle-env.sh

echo ""
echo "=== Step 4: リスナーの状態確認 ==="
lsnrctl status

echo ""
echo "=== インストール完了 ==="
echo "SQL*Plus で接続するには: sqlplus / as sysdba"
