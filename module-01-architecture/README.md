# Module 1: データベースの心臓部を知る

Oracle Database は、単なる「データを保存する箱」ではありません。
複数のメモリ領域・バックグラウンドプロセス・ファイル群が協調して動作する、精密なシステムです。
このモジュールでは、Oracle Database の内部構造（アーキテクチャ）を理解し、実際に自分の手でインストールから起動確認まで行うことで、DBA としての第一歩を踏み出します。

---

## 学習目標

- Oracle Database の「インスタンス」と「データベース」の違いを説明できる
- SGA（System Global Area）に含まれる主要なメモリ領域の役割を説明できる
- 主要なバックグラウンドプロセス（DBWn, LGWR, CKPT, SMON, PMON）の役割を説明できる
- Oracle Database 21c XE を `dnf` コマンドでインストールし、起動確認できる
- DBCA の役割と使用場面を説明できる
- SQL\*Plus でインスタンスに接続し、基本的な情報を取得できる

---

## 第1章: Oracle Database アーキテクチャ

### インスタンスとデータベース

Oracle を理解する上で最も重要な概念が「インスタンス」と「データベース」の区別です。

```text
┌─────────────────────────────────────────────┐
│              Oracle インスタンス              │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │   SGA（System Global Area）          │  │
│  │  ┌────────────┐ ┌────────────────┐  │  │
│  │  │ Shared Pool│ │DB Buffer Cache │  │  │
│  │  └────────────┘ └────────────────┘  │  │
│  │  ┌────────────────────────────────┐  │  │
│  │  │     Redo Log Buffer            │  │  │
│  │  └────────────────────────────────┘  │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  バックグラウンドプロセス                      │
│  DBWn  LGWR  CKPT  SMON  PMON  ARCn ...   │
└─────────────────────────────────────────────┘
          ↕ 読み書き
┌─────────────────────────────────────────────┐
│              データベース（ファイル群）          │
│  データファイル  制御ファイル  REDOログファイル   │
└─────────────────────────────────────────────┘
```

| 用語 | 意味 |
| :--- | :--- |
| **インスタンス** | メモリ（SGA）＋バックグラウンドプロセスの集合体。OS 上で動作する「稼働中の Oracle」 |
| **データベース** | ディスク上のファイル群（データファイル・制御ファイル・REDOログ）。電源を切っても残る実体 |

インスタンスは起動すると SGA をメモリに確保し、バックグラウンドプロセスを起動します。
インスタンスを起動しなければ、データベース（ファイル）にアクセスできません。

---

### SGA（System Global Area）

SGA はすべてのサーバープロセスとバックグラウンドプロセスが共有するメモリ領域です。
Oracle を起動すると OS のメモリ上に確保され、停止すると解放されます。

| メモリ領域 | 役割 |
| :--- | :--- |
| **Shared Pool** | SQL の解析結果（解析ツリー）やデータディクショナリのキャッシュを保持。同じ SQL を再実行する際に解析コストを削減する |
| **DB Buffer Cache** | データファイルから読み込んだデータブロックをキャッシュする。ディスク I/O を減らし、クエリを高速化する |
| **Redo Log Buffer** | コミット前のトランザクション変更情報（Redo）を一時的に保持。LGWR が定期的にディスクへ書き出す |
| **Large Pool** | バックアップ（RMAN）や並列処理の大規模メモリ割り当てに使用（オプション） |
| **Java Pool** | Oracle JVM を使用する場合に使用（オプション） |

---

### PGA（Program Global Area）

PGA は各サーバープロセス（セッション）が**個別に**持つメモリ領域です。SGA と異なり、共有されません。
ソートやハッシュ結合などの作業領域として使われます。セッションが切断されると解放されます。

---

### 主要バックグラウンドプロセス

Oracle が起動すると自動で起動するプロセス群です。

| プロセス | 役割 |
| :--- | :--- |
| **DBWn** (Database Writer) | DB Buffer Cache の変更済みブロック（ダーティブロック）をデータファイルに書き出す |
| **LGWR** (Log Writer) | Redo Log Buffer の内容を REDOログファイルに書き出す。コミット時に必ず実行される |
| **CKPT** (Checkpoint) | チェックポイント発生時に制御ファイルとデータファイルのヘッダを更新し、DBWn に書き出しを指示する |
| **SMON** (System Monitor) | インスタンス障害後の自動リカバリ（クラッシュリカバリ）を担う |
| **PMON** (Process Monitor) | 異常終了したユーザープロセスのリソース（ロック・メモリ）を解放するクリーンアップ担当 |
| **ARCn** (Archiver) | アーカイブログモード時に、使用済み REDOログファイルをアーカイブ先にコピーする |

---

### データベースを構成するファイル

| ファイル種別 | 役割 |
| :--- | :--- |
| **データファイル** (`.dbf`) | 表・索引などの実データを格納する。表領域と1対多の関係 |
| **制御ファイル** | データベースの物理構造（ファイルの場所・SCN など）を記録。起動時に必ず参照される |
| **REDOログファイル** | トランザクションの変更履歴を記録。障害時のリカバリに使用。グループ単位でローテーションする |

---

## 第2章: インストールと DBCA

### oracle-database-preinstall-21c の役割

Oracle Database のインストールには、OS レベルの事前設定が多数必要です。
`oracle-database-preinstall-21c` パッケージはこれらを自動化します。

自動設定される主な内容は以下のとおりです。

- カーネルパラメータ（`shmmax`, `semaphore` など）の最適化
- `oracle` ユーザーと `oinstall` / `dba` グループの作成
- `/etc/security/limits.conf` のリソース制限設定

---

### oracle-database-xe-21c のインストール構成

インストール後の主要なパスは以下のとおりです。

| パス | 内容 |
| :--- | :--- |
| `ORACLE_BASE` = `/opt/oracle` | Oracle ソフトウェア全体のベースディレクトリ |
| `ORACLE_HOME` = `/opt/oracle/product/21c/dbhomeXE` | データベースバイナリ（sqlplus, lsnrctl など）の格納先 |
| `ORACLE_SID` = `XE` | このコンテナで動作するデータベースの識別子 |

---

### DBCA（Database Configuration Assistant）

DBCA は Oracle が提供する GUI/CUI ツールで、データベースの作成・削除・変更を対話的に行えます。

| 操作 | 手作法 | DBCA |
| :--- | :--- | :--- |
| パラメータ設定 | 手動で `init.ora` を編集 | ウィザードで設定 |
| 表領域・ファイル作成 | CREATE TABLESPACE 文を手動実行 | 自動生成 |
| ミス防止 | 自己責任 | バリデーションあり |

Oracle Database 21c XE では、`configure` コマンド実行時に DBCA が内部的に呼び出され、
初期データベース（SID: XE）が自動作成されます。

---

## ハンズオン手順

> **前提**: このコンテナの Dockerfile で `oracle-database-preinstall-21c` はすでにインストール済みです。
> ここでは Oracle Database 本体のインストールから行います。

---

### 事前準備: Oracle Database 21c XE RPM のダウンロード

#### なぜ手動ダウンロードが必要か

`oracle-database-free-23ai`（23ai 版）は Oracle Linux の標準 dnf リポジトリから `dnf install` 一発で入りますが、
`oracle-database-xe-21c` は通常の dnf リポジトリには含まれていません。

また、Oracle Database XE は**無償で使用できますが、オープンソースではありません**。
Oracle の利用規約（Oracle Free Use Terms and Conditions）により **再配布（redistribution）が明示的に禁止**されているため、
RPM ファイルを GitHub などの公開リポジトリに置くことはライセンス違反になります。
このため、各自が oracle.com から直接ダウンロードする必要があります。

> この制約を知っておくことは、将来 Oracle Database を本番環境で運用する DBA として重要な知識です。

#### ダウンロード手順

1. **ブラウザで** Oracle の XE ダウンロードページを開く
   - URL: `https://www.oracle.com/database/technologies/xe-downloads.html`
2. Oracle アカウントでサインイン（無料、未登録なら作成）
3. **Oracle Database 21c Express Edition for Linux x86-64** の RPM をダウンロード
   - ファイル名: `oracle-database-xe-21c-21.0.0-0.0.el8.x86_64.rpm`（約 1.7 GB）
4. ダウンロードした RPM を Codespace にアップロードする
   - VS Code の左側 Explorer パネルでプロジェクトルート（`/workspaces/starter-oracle-db/`）を右クリック →「Upload...」を選択
   - ダウンロードした RPM ファイルを選んでアップロード
   - `.gitignore` に `*.rpm` を登録済みのため、誤ってコミットされる心配はありません

---

### Step 1: RPM ファイルの配置確認

```bash
# アップロードした RPM がプロジェクトルートにあることを確認
ls /workspaces/starter-oracle-db/oracle-database-xe-21c-*.rpm
```

実行すると以下のように出力されます。

```text
/workspaces/starter-oracle-db/oracle-database-xe-21c-1.0-1.ol8.x86_64.rpm
```

ファイルが見当たらない場合は、事前準備の手順に戻ってアップロードしてください。

### Step 2: Oracle Database 21c XE のインストール

```bash
# ローカル RPM からインストール（数分かかります）
# ORACLE_DOCKER_INSTALL=true はコンテナ環境での su エラーを回避するために必要
sudo ORACLE_DOCKER_INSTALL=true dnf localinstall -y /workspaces/starter-oracle-db/oracle-database-xe-21c-*.rpm
```

インストール完了後、`/opt/oracle/product/21c/dbhomeXE/` に
バイナリが展開されていることを確認します。

```bash
ls /opt/oracle/product/21c/dbhomeXE/bin/sqlplus
```

### Step 3: 環境変数の設定

Oracle のバイナリ（`sqlplus`, `lsnrctl` など）を PATH に通すため、環境変数ファイルを作成します。

### なぜ3か所に設定するのか

Linux では、シェル（ターミナル）の起動方法によって「どの設定ファイルを読み込むか」が変わります。
これを理解せずにいると「あるターミナルでは `sqlplus` が使えるのに、新しく開いたターミナルでは使えない」という状況が起きます。

シェルの種類は大きく2つに分かれます。

**ログインシェル** — サーバーに「ログイン」するときに起動するシェルです。

- SSH でサーバーに接続したとき
- `su - oracle` のように `-` オプション付きでユーザーを切り替えたとき
- 読み込まれる設定ファイル: `/etc/profile.d/*.sh`、`~/.bash_profile`

**非ログインシェル** — すでにログイン済みの環境から新しく開くシェルです。

- VS Code のターミナルで `+` ボタンを押して新しいタブを開いたとき
- スクリプト内で `bash` を実行したとき
- 読み込まれる設定ファイル: `~/.bashrc`（`~/.bash_profile` は読み込まれない）

Codespaces の VS Code ターミナルは**非ログインシェル**です。
`~/.bashrc` に設定がなければ、新しいターミナルを開くたびに `sqlplus` が見つからなくなります。

これらをまとめると、Oracle のバイナリをどの起動方法でも確実に使えるよう3か所に設定します。

| ファイル | 読み込まれるシェル | 主な起動場面 |
| :--- | :--- | :--- |
| `/etc/profile.d/oracle-env.sh` | ログインシェル（システム全体） | SSH 接続、`su -` |
| `~/.bash_profile` | ログインシェル（oracle ユーザー） | SSH 接続、`su - oracle` |
| `~/.bashrc` | **非ログインシェル（oracle ユーザー）** | **VS Code のターミナル**を新規に開いたとき |

`setup-env.sh` を実行すると、上記3ファイルの作成と現在のシェルへの反映を一括で行います。

```bash
bash /workspaces/starter-oracle-db/module-01-architecture/setup-env.sh
```

実行すると以下のように出力されます。

```text
=== /etc/profile.d/oracle-env.sh を作成（システム全体向け） ===
作成完了: /etc/profile.d/oracle-env.sh

=== ~/.bash_profile に追記（oracle ユーザーのログインシェル向け） ===
追記完了: ~/.bash_profile

=== ~/.bashrc に追記（VS Code ターミナルなど非ログインシェル向け） ===
追記完了: ~/.bashrc

=== 現在のシェルに環境変数を反映 ===
ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
ORACLE_SID=XE

=== sqlplus の確認 ===
/opt/oracle/product/21c/dbhomeXE/bin/sqlplus
環境変数の設定が完了しました。
```

> **注意**: `bash` で実行するとサブシェルが起動するため、スクリプト内の環境変数の反映は**今開いているターミナルには届きません**。
> 以下のコマンドで現在のシェルに手動で読み込みます。

```bash
source ~/.bashrc
```

以下を実行して確認します。

```bash
echo $ORACLE_HOME
# /opt/oracle/product/21c/dbhomeXE と表示されれば成功
```

### Step 4: データベースの設定・初期化

```bash
# 初期データベース（SID: XE）を作成・設定する
# ORACLE_HOSTNAME=$HOSTNAME はコンテナ環境でのホスト名解決エラーを回避するために必要
sudo ORACLE_HOSTNAME=$HOSTNAME /etc/init.d/oracle-xe-21c configure
```

> プロンプトでパスワードの入力を求められます。  
> Oracleでは、入力するパスワードは8文字以上で、大文字1文字、小文字1文字、および数字[0-9]を1つ以上含むことを推奨しています。  
> なお、このパスワードはSYS、SYSTEM、およびPDBADMINアカウントで共通して使用されます。  
> このパスワードは以降の SQL\*Plus 接続に使用するので忘れずに記録しておいてください。

設定には数分かかります。完了後に以下が表示されれば成功です。

```text
Database creation complete.
```

### Step 5: リスナーの起動確認

```bash
# リスナーの状態を確認
lsnrctl status
```

期待される出力（抜粋）

```text
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: ...
Start Date                ...
Uptime                    ...
```

### Step 6: SQL\*Plus で接続確認

```bash
# OS 認証（パスワード不要）で SYSDBA として接続
sqlplus / as sysdba
```

接続できたら、インスタンスの状態を確認します。

```sql
-- インスタンスの状態を確認
SELECT status FROM v$instance;

-- 結果: OPEN であれば正常
-- STATUS
-- ------
-- OPEN
```

SQL\*Plus を終了します。

```sql
EXIT
```

### Step 7: バックグラウンドプロセスの確認

別のスクリプトを使って、OS 上で動作している Oracle プロセスを確認します。

```bash
# check-processes.sh を実行
bash /workspaces/starter-oracle-db/module-01-architecture/check-processes.sh
```

または直接 `ps` コマンドで確認します。

```bash
ps aux | grep -E 'xe_' | grep -v grep
```

> **補足**: Oracle Database XE では、バックグラウンドプロセスのプレフィックスは `ora_` ではなく `xe_` になります。

期待される出力例（一部）

```text
oracle   ...  xe_pmon_XE
oracle   ...  xe_dbw0_XE
oracle   ...  xe_lgwr_XE
oracle   ...  xe_ckpt_XE
oracle   ...  xe_smon_XE
```

### Step 8: SGA 情報の確認

```bash
sqlplus -s / as sysdba <<'EOF'
SELECT name, ROUND(bytes/1024/1024, 1) AS mb
FROM   v$sgainfo
ORDER BY bytes DESC;
EXIT
EOF
```

実行すると以下のように出力されます。

```text
NAME                                  MB
-------------------------------- -------
Maximum SGA Size                  1520.0
...
Shared Pool Size                   272.0
Buffer Cache Size                  480.0
...
```

---

## 確認してみよう

1. Oracle の「インスタンス」と「データベース」は何が違いますか？それぞれ OS 上でどのように存在していますか？
2. SGA に含まれる主要なメモリ領域を3つ挙げ、それぞれがどのような役割を担っているか説明してください。
3. LGWR（Log Writer）はどのタイミングで動作しますか？また、なぜコミット時に必ず書き込みが行われるのでしょうか？
4. `oracle-database-preinstall-21c` パッケージをインストールする目的は何ですか？これがないと何が起きると考えられますか？
5. DBCA を使わずに手動でデータベースを作成できますか？DBCA を使う利点は何でしょうか？

---

| | [全章目次](../README.md) | [Module 2: インスタンスと接続の制御 →](../module-02-instance/README.md) |
|:---|:---:|---:|
