#!/bin/bash
# Oracle Database 21c XE インストールスクリプト
# 実行前に sudo 権限があることを確認すること

set -e

echo "=== Step 1: Oracle Database 21c XE のインストール ==="
sudo dnf install -y oracle-database-xe-21c

echo ""
echo "=== Step 2: 初期データベースの設定（パスワード入力を求められます） ==="
sudo /etc/init.d/oracle-xe-21c configure

echo ""
echo "=== Step 3: 環境変数の読み込み ==="
source /etc/profile.d/oracle-env.sh

echo ""
echo "=== Step 4: リスナーの状態確認 ==="
lsnrctl status

echo ""
echo "=== インストール完了 ==="
echo "SQL*Plus で接続するには: sqlplus / as sysdba"
