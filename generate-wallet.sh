#!/bin/bash
# SQL Developer 接続用 TCPS wallet 生成スクリプト
# 初回セットアップ時と Codespaces 再ビルド後に実行してください
#
# 使用方法: bash generate-wallet.sh

set -e

ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
SERVER_WALLET=/opt/oracle/admin/XE/tcps_wallet
CLIENT_WALLET_DIR=/workspaces/starter-oracle-db/sql-developer-wallet
NET_ADMIN=/opt/oracle/homes/OraDBHome21cXE/network/admin

echo "=== TCPS Wallet 生成スクリプト ==="
echo ""

# ────────────────────────────────────────────
# 1. サーバー Wallet の生成（CN=localhost）
# ────────────────────────────────────────────
echo "--- [1/5] サーバー Wallet を作成中 ---"
mkdir -p "$SERVER_WALLET"

if [ -f "$SERVER_WALLET/cwallet.sso" ]; then
    echo "既存のサーバー Wallet を削除して再作成します..."
    rm -f "$SERVER_WALLET/cwallet.sso" "$SERVER_WALLET/ewallet.p12"
fi

$ORACLE_HOME/bin/orapki wallet create \
    -wallet "$SERVER_WALLET" \
    -auto_login_only

$ORACLE_HOME/bin/orapki wallet add \
    -wallet "$SERVER_WALLET" \
    -dn "CN=localhost" \
    -keysize 2048 \
    -self_signed \
    -validity 3650 \
    -auto_login_only

echo "サーバー Wallet を作成しました: $SERVER_WALLET"

# ────────────────────────────────────────────
# 2. listener.ora の設定（TCPS 2484 追加）
# ────────────────────────────────────────────
echo ""
echo "--- [2/5] listener.ora を設定中 ---"
cat > "$NET_ADMIN/listener.ora" << 'LISTENEREOF'
# listener.ora - Oracle Net Listener configuration
# TCP 1521 (標準接続) + TCPS 2484 (SQL Developer wallet 接続)

DEFAULT_SERVICE_LISTENER = XE

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
    )
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCPS)(HOST = 0.0.0.0)(PORT = 2484))
    )
  )

SSL_CLIENT_AUTHENTICATION = FALSE

WALLET_LOCATION =
  (SOURCE =
    (METHOD = FILE)
    (METHOD_DATA =
      (DIRECTORY = /opt/oracle/admin/XE/tcps_wallet)
    )
  )
LISTENEREOF

echo "listener.ora を更新しました。"

# ────────────────────────────────────────────
# 3. sqlnet.ora の設定（SSL/Wallet 設定追加）
# ────────────────────────────────────────────
echo ""
echo "--- [3/5] sqlnet.ora を設定中 ---"
cat > "$NET_ADMIN/sqlnet.ora" << 'SQLNETEOF'
# sqlnet.ora - Oracle Net configuration

NAMES.DIRECTORY_PATH = (TNSNAMES, EZCONNECT)
SSL_CLIENT_AUTHENTICATION = FALSE
WALLET_LOCATION =
  (SOURCE =
    (METHOD = FILE)
    (METHOD_DATA =
      (DIRECTORY = /opt/oracle/admin/XE/tcps_wallet)
    )
  )
SSL_VERSION = 1.2
SQLNETEOF

echo "sqlnet.ora を更新しました。"

# ────────────────────────────────────────────
# 4. リスナーの再起動
# ────────────────────────────────────────────
echo ""
echo "--- [4/5] Oracle リスナーを再起動中 ---"
$ORACLE_HOME/bin/lsnrctl stop 2>/dev/null || true
sleep 1
$ORACLE_HOME/bin/lsnrctl start
sleep 3

# TCPS 2484 が起動しているか確認
if ss -tlnp | grep -q ":2484"; then
    echo "TCPS リスナーがポート 2484 で起動しました。"
else
    echo "WARNING: ポート 2484 が確認できません。lsnrctl status で確認してください。"
fi

# ────────────────────────────────────────────
# 5. クライアント Wallet の生成
# ────────────────────────────────────────────
echo ""
echo "--- [5/5] クライアント Wallet を生成中 ---"

# サーバー証明書をエクスポート
$ORACLE_HOME/bin/orapki wallet export \
    -wallet "$SERVER_WALLET" \
    -dn "CN=localhost" \
    -cert /tmp/server-tcps.crt

# クライアント Wallet ディレクトリを初期化
rm -rf "$CLIENT_WALLET_DIR"
mkdir -p "$CLIENT_WALLET_DIR/wallet"

# クライアント Wallet 作成（サーバー証明書を trusted cert として登録）
$ORACLE_HOME/bin/orapki wallet create \
    -wallet "$CLIENT_WALLET_DIR/wallet" \
    -auto_login_only

$ORACLE_HOME/bin/orapki wallet add \
    -wallet "$CLIENT_WALLET_DIR/wallet" \
    -trusted_cert \
    -cert /tmp/server-tcps.crt \
    -auto_login_only

# tnsnames.ora（クライアント用）
cat > "$CLIENT_WALLET_DIR/wallet/tnsnames.ora" << 'TNSNAMESEOF'
XE_SECURE =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCPS)(HOST = localhost)(PORT = 2484))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = xe)
    )
  )
TNSNAMESEOF

# sqlnet.ora（クライアント用）
cat > "$CLIENT_WALLET_DIR/wallet/sqlnet.ora" << 'SQLNETCLIENTEOF'
SSL_CLIENT_AUTHENTICATION = FALSE
SSL_VERSION = 1.2
NAMES.DIRECTORY_PATH = (TNSNAMES)
SQLNETCLIENTEOF

# wallet.zip にパッケージ
cd "$CLIENT_WALLET_DIR"
zip -j wallet.zip wallet/*
rm -rf wallet

echo "クライアント Wallet を作成しました: $CLIENT_WALLET_DIR/wallet.zip"
rm -f /tmp/server-tcps.crt

# ────────────────────────────────────────────
# 完了メッセージ
# ────────────────────────────────────────────
echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "【wallet.zip の取得方法】"
echo "  VS Code のエクスプローラーで以下を右クリック → ダウンロード:"
echo "  sql-developer-wallet/wallet.zip"
echo ""
echo "【SQL Developer での接続設定】"
echo "  1. 「新規接続」→ 接続タイプ: Cloud Wallet"
echo "  2. 「参照」で wallet.zip を指定"
echo "  3. サービス: XE_SECURE"
echo "  4. ユーザー名・パスワードを入力 → 接続"
echo ""
echo "  ※ Oracle Instant Client は不要です"
echo "  ※ VS Code で Codespaces に接続した状態で使用してください（ポート 2484 が転送されます）"
