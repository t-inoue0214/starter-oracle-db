# Oracle Silver DBA 習得カリキュラム (第1章〜第8章 重点攻略)

## 1. 目的
- Oracle Database 21c のインストールから、インスタンス管理、記憶域構造、一貫性管理までの基礎を完全にマスターする。
- 黒本の前半（DBAパートの核心）を実機演習を通じて深く理解する。
- 黒本の全23章を「構造的」に理解し、Codespaces上で実機確認を行う。
- 単なる暗記ではなく、DBAとしての「管理の流れ」を身につける。

## 2. 学習環境
- **プラットフォーム**: GitHub Codespaces (Oracle Linux 8)
- **DBエディション**: Oracle Database Free 23ai
- **ツール**: `SQL*Plus`, `lsnrctl`, `adrci`, 各種初期化パラメータファイル(PFILE/SPFILE)

## ■ 学習カリキュラム（全7モジュール）

### Module 1: データベースの心臓部を知る（第1章・第2章）
- **対象**: アーキテクチャ、インストール、DBCA
- **ポイント**: Codespacesに手動でインストールを行い、バックグラウンドプロセスやメモリ構造(SGA/PGA)がOS上でどう見えているかを確認する。
- **実習**: `dnf install` から `oracle-free-23ai configure` までの全工程。

### Module 2: インスタンスと接続の制御（第3章・第4章）
- **対象**: 起動・停止、初期化パラメータ、Oracle Net(リスナー)
- **ポイント**: SQL*Plusでの起動フェーズ(NOMOUNT〜OPEN)の変化と、外部から繋ぐためのネットワーク設定を学ぶ。
- **実習**: `STARTUP` / `SHUTDOWN` の実行、`lsnrctl` コマンド操作、`tnsnames.ora` の記述。

### Module 3: 守りとセキュリティ（第5章・第8章）
- **対象**: ユーザー管理、権限・ロール、UNDOの管理
- **ポイント**: 「誰が何を使えるか」と「トランザクションの整合性」をセットで学ぶ。UNDOはJavaアプリ開発時の「スナップショットが古すぎます」エラーの理解に直結。
- **実習**: ユーザー作成、プロファイルによる制限、大量更新時のUNDO表領域監視。

### Module 4: データの器（ストレージ）管理（第6章・第7章）
- **対象**: 表領域、データファイル、セグメント・ブロック構造
- **ポイント**: 論理構造(表領域)と物理構造(ファイル)の紐付け。DBAとして最も重要な「ディスク容量管理」の基礎。
- **実習**: 表領域の作成、データファイルの追加・リサイズ、OMF(Oracle Managed Files)の動作確認。

### Module 5: データの搬入・搬出（第9章）
- **対象**: Data Pump, SQL*Loader, 外部表
- **ポイント**: 実務で必ず発生する「データの移行・一括ロード」の手法。
- **実習**: `expdp` / `impdp` によるスキーマ移行、CSVファイルからの `sqlldr` ロード。

### Module 6: 開発者の一歩先を行くSQL（第10章〜第18章）
- **対象**: 標準SQL、関数、結合、副問合せ、集合演算、DML
- **ポイント**: 既に知っているSELECT文を「Oracleの特性」や「高度な結合」に広げる。ここは比較的スムーズに進むはず。
- **実習**: 複雑な結合SQLの作成、分析用集計関数の使用。

### Module 7: オブジェクトの最適化と整合性（第19章〜第23章）
- **対象**: DDL、表の管理、索引、ビュー、シーケンス、制約、タイムゾーン
- **ポイント**: 良いDB設計に欠かせないオブジェクト。特に「索引(インデックス)」と「制約」はDBA・開発者双方にとって最重要項目。
- **実習**: 索引の作成と実行計画の確認、制約違反時の挙動確認、ビューの作成。

## 4. Claude Code への追加指示案
- 「第6章の『表領域の管理』を練習したい。データファイルを別のディレクトリに移動する手順を、実際のコマンドライン操作とともにガイドして。」
- 「UNDO表領域が不足した時に、トランザクションがどうエラーになるかをシミュレーションするSQLスクリプトを書いて。」
- 「現在のSGAのメモリ割り当て状況（第1章）を、データディクショナリビューを使って表示するクエリを教えて。」
- 「現在、Module 2（第3章・第4章）を学習中。Codespacesのターミナルで初期化パラメータファイルを pfile として書き出し、それを編集して最大セッション数を変更してから再起動する手順をガイドして。」


## 各章 README の「確認してみよう」セクション

すべての章の `README.md` に、本文の後・ナビゲーションバーの前に「確認してみよう」セクションを設ける。

```markdown
## 確認してみよう

1. （問い）
2. （問い）
3. （問い）
```

### 作成ルール

- 問い数は **3問〜6問** とする
- 問いは、その章で学んだ概念・操作・理由（Why）を自分の言葉で説明できるかを確かめる内容にする
- 単純な「Yes/No」ではなく、「〜とは何ですか？」「なぜ〜が必要なのですか？」など、理解度を問う形式にする
- 回答は記載しない（学習者自身が考える余白を残す）
- 問いの順番は「簡単 → やや難しい」の順に並べる

---

## 各章 README のナビゲーションバー

すべての章の `README.md` 末尾（本文の後、最終行）に以下のテーブル形式のナビゲーションバーを置く。

```markdown
| [← 第NN章: タイトル](../前章フォルダ名/README.md) | [全章目次](../README.md) | [第NN章: タイトル →](../次章フォルダ名/README.md) |
|:---|:---:|---:|
```

- ルート `README.md` へのパスは **`../README.md`**（章フォルダから1階層上）
- 前章がない場合: 左セルを空欄にする
- 次章がない場合: 右セルをリンクなしのテキスト `最終章` にする
- ナビゲーションバーの直前に `---` 区切り線を入れる

---

## ディレクトリ構成

### 基本方針

章ごとのファイル数によって配置方法を使い分ける。

| 状況 | 配置方法 |
| :--- | :--- |
| README.md **のみ**の章 | プロジェクト直下に `module-NN-keyword.md` として配置 |
| README.md **以外のファイルも存在**する章 | `module-NN-keyword/` フォルダを作成し、中に `README.md` を配置 |

### 命名規則

```
module-NN-keyword
```

- `NN`: ゼロ埋め2桁のモジュール番号（01〜07）
- `keyword`: そのモジュールの中心概念を表す **英単語1語**（grep・目視で素早く識別できるもの）

### 各モジュールのディレクトリ案

カリキュラムの実習内容（SQL スクリプト・設定ファイル・データファイル等）を考慮すると、
全モジュールで README.md 以外のファイルが発生するため、すべてフォルダ構成とする。

| モジュール | フォルダ名 | keyword の根拠 | 想定される追加ファイル例 |
| :--- | :--- | :--- | :--- |
| Module 1（第1・2章） | `module-01-architecture` | アーキテクチャ・インストールが中心 | `install.sh`, `check-processes.sh` |
| Module 2（第3・4章） | `module-02-instance` | インスタンス制御・起動停止が中心 | `tnsnames.ora`, `listener.ora`, `init.ora` |
| Module 3（第5・8章） | `module-03-security` | ユーザー管理・権限・ロールが中心 | `create-users.sql`, `grant-roles.sql`, `monitor-undo.sql` |
| Module 4（第6・7章） | `module-04-storage` | 表領域・ストレージ管理が中心 | `create-tablespace.sql`, `manage-datafiles.sql` |
| Module 5（第9章） | `module-05-datapump` | Data Pump・SQL\*Loader が中心 | `sample-data.csv`, `load.ctl`, `export.par` |
| Module 6（第10〜18章） | `module-06-sql` | SQL・DML 操作が中心 | `join-examples.sql`, `aggregation.sql` |
| Module 7（第19〜23章） | `module-07-objects` | オブジェクト管理（索引・制約等）が中心 | `create-indexes.sql`, `constraints.sql`, `views.sql` |

### プロジェクト全体の構成イメージ

```
starter-oracle-db/
├── README.md                          ← 全体目次・学習の始め方
├── CODE_SPACES_SERVICE.md
├── assets/
├── docs/
│   └── plans/
│       └── main-plan.md
├── module-01-architecture/
│   ├── README.md                      ← Module 1 の解説（第1・2章）
│   └── install.sh                     ← 実習用スクリプト
├── module-02-instance/
│   ├── README.md
│   ├── tnsnames.ora
│   └── listener.ora
│       ... （以下同様）
└── module-07-objects/
    ├── README.md
    └── create-indexes.sql
```

### ナビゲーションバーのパス例

Module 2 の `README.md` から見た場合:

```markdown
| [← Module 1: データベースの心臓部を知る](../module-01-architecture/README.md) | [全章目次](../README.md) | [Module 3: 守りとセキュリティ →](../module-03-security/README.md) |
|:---|:---:|---:|
```
