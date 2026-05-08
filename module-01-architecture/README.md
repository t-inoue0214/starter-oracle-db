# Module 1: データベースの心臓部を知る

Oracle Database は、単なる「データを保存する箱」ではありません。
複数のメモリ領域・バックグラウンドプロセス・ファイル群が協調して動作する、精密なシステムです。
このモジュールでは、Oracle Database の内部構造（アーキテクチャ）を理解し、実際に自分の手でインストールから起動確認まで行うことで、DBA としての第一歩を踏み出します。

---

## 学習目標

- Oracle Database の「インスタンス」と「データベース」の違いを説明できる
- SGA（System Global Area）に含まれる主要なメモリ領域の役割を説明できる
- 主要なバックグラウンドプロセス（DBWn, LGWR, CKPT, SMON, PMON）の役割を説明できる
- Oracle Database 23ai Free を `dnf` コマンドでインストールし、起動確認できる
- DBCA の役割と使用場面を説明できる
- SQL\*Plus でインスタンスに接続し、基本的な情報を取得できる

---

## 第1章: Oracle Database アーキテクチャ

### インスタンスとデータベース

Oracle を理解する上で最も重要な概念が「インスタンス」と「データベース」の区別です。

```
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
インスタンスを起動しなければ、データベース（ファイル）にアクセスすることはできません。

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

### oracle-database-preinstall-23ai の役割

Oracle Database のインストールには、OS レベルの事前設定が多数必要です。
`oracle-database-preinstall-23ai` パッケージはこれらを自動化します。

自動設定される主な内容:
- カーネルパラメータ（`shmmax`, `semaphore` など）の最適化
- `oracle` ユーザーと `oinstall` / `dba` グループの作成
- `/etc/security/limits.conf` のリソース制限設定

---

### oracle-database-free-23ai のインストール構成

インストール後の主要なパス:

| パス | 内容 |
| :--- | :--- |
| `ORACLE_BASE` = `/opt/oracle` | Oracle ソフトウェア全体のベースディレクトリ |
| `ORACLE_HOME` = `/opt/oracle/product/23ai/dbhomeFree` | データベースバイナリ（sqlplus, lsnrctl など）の格納先 |
| `ORACLE_SID` = `FREE` | このコンテナで動作するデータベースの識別子 |

---

### DBCA（Database Configuration Assistant）

DBCA は Oracle が提供する GUI/CUI ツールで、データベースの作成・削除・変更を対話的に行えます。

| 操作 | 手作法 | DBCA |
| :--- | :--- | :--- |
| パラメータ設定 | 手動で `init.ora` を編集 | ウィザードで設定 |
| 表領域・ファイル作成 | CREATE TABLESPACE 文を手動実行 | 自動生成 |
| ミス防止 | 自己責任 | バリデーションあり |

Oracle Database 23ai Free では、`configure` コマンド実行時に DBCA が内部的に呼び出され、
初期データベース（SID: FREE）が自動作成されます。

---

## ハンズオン手順

> **前提**: このコンテナの Dockerfile で `oracle-database-preinstall-23ai` はすでにインストール済みです。
> ここでは Oracle Database 本体のインストールから行います。

### Step 1: Oracle リポジトリの確認

```bash
# oracle リポジトリが有効になっているか確認
sudo dnf repolist | grep oracle
```

期待される出力例:
```
ol8_baseos_latest   Oracle Linux 8 BaseOS Latest (x86_64)
ol8_appstream       Oracle Linux 8 Application Stream (x86_64)
```

### Step 2: Oracle Database 23ai Free のインストール

```bash
# インストール（数分かかります）
sudo dnf install -y oracle-database-free-23ai
```

インストール完了後、`/opt/oracle/product/23ai/dbhomeFree/` に
バイナリが展開されていることを確認します。

```bash
ls /opt/oracle/product/23ai/dbhomeFree/bin/sqlplus
```

### Step 3: データベースの設定・初期化

```bash
# 初期データベース（SID: FREE）を作成・設定する
sudo /etc/init.d/oracle-free-23ai configure
```

> プロンプトでパスワードの入力を求められます。SYS / SYSTEM ユーザーのパスワードを設定してください。  
> このパスワードは以降の SQL\*Plus 接続に使用するので忘れずに記録しておいてください。

設定には数分かかります。完了後に以下が表示されれば成功です:
```
Database configuration completed successfully.
```

### Step 4: リスナーの起動確認

```bash
# 環境変数を読み込む
source /etc/profile.d/oracle-env.sh

# リスナーの状態を確認
lsnrctl status
```

期待される出力（抜粋）:
```
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: ...
Start Date                ...
Uptime                    ...
```

### Step 5: SQL\*Plus で接続確認

```bash
# OS 認証（パスワード不要）で SYSDBA として接続
sqlplus / as sysdba
```

接続できたら、インスタンスの状態を確認します:

```sql
-- インスタンスの状態を確認
SELECT status FROM v$instance;

-- 結果: OPEN であれば正常
-- STATUS
-- ------
-- OPEN
```

SQL\*Plus を終了します:
```sql
EXIT
```

### Step 6: バックグラウンドプロセスの確認

別のスクリプトを使って、OS 上で動作している Oracle プロセスを確認します:

```bash
# check-processes.sh を実行
bash ~/module-01-architecture/check-processes.sh
```

または直接 `ps` コマンドで確認:

```bash
ps aux | grep -E 'ora_' | grep -v grep
```

期待される出力例（一部）:
```
oracle   1234  ... ora_dbw0_FREE
oracle   1235  ... ora_lgwr_FREE
oracle   1236  ... ora_ckpt_FREE
oracle   1237  ... ora_smon_FREE
oracle   1238  ... ora_pmon_FREE
```

### Step 7: SGA 情報の確認

```bash
sqlplus -s / as sysdba <<'EOF'
SELECT name, ROUND(bytes/1024/1024, 1) AS mb
FROM   v$sgainfo
ORDER BY bytes DESC;
EXIT
EOF
```

期待される出力例:
```
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
4. `oracle-database-preinstall-23ai` パッケージをインストールする目的は何ですか？これがないと何が起きると考えられますか？
5. DBCA を使わずに手動でデータベースを作成することは可能ですか？DBCA を使う利点は何でしょうか？

---

| | [全章目次](../README.md) | [Module 2: インスタンスと接続の制御 →](../module-02-instance/README.md) |
|:---|:---:|---:|
