#!/bin/bash
# Oracle Database 環境変数の設定スクリプト

set -e

echo "=== /etc/profile.d/oracle-env.sh を作成（システム全体向け） ==="
sudo tee /etc/profile.d/oracle-env.sh > /dev/null << 'EOF'
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
export ORACLE_SID=XE
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
EOF
sudo chmod +x /etc/profile.d/oracle-env.sh
echo "作成完了: /etc/profile.d/oracle-env.sh"

echo ""
echo "=== ~/.bash_profile に追記（oracle ユーザーのログインシェル向け） ==="
cat >> ~/.bash_profile << 'EOF'

# Oracle Database 環境変数
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
export ORACLE_SID=XE
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
EOF
echo "追記完了: ~/.bash_profile"

echo ""
echo "=== ~/.bashrc に追記（VS Code ターミナルなど非ログインシェル向け） ==="
cat >> ~/.bashrc << 'EOF'

# Oracle Database 環境変数
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
export ORACLE_SID=XE
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
EOF
echo "追記完了: ~/.bashrc"

echo ""
echo "=== 現在のシェルに環境変数を反映 ==="
source /etc/profile.d/oracle-env.sh
echo "ORACLE_HOME=$ORACLE_HOME"
echo "ORACLE_SID=$ORACLE_SID"

echo ""
echo "=== sqlplus の確認 ==="
which sqlplus
echo "環境変数の設定が完了しました。"
