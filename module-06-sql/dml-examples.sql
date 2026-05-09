-- Module 6 実習: DML（INSERT / UPDATE / DELETE / MERGE）のサンプル
-- 使用方法: sqlplus sql_user/SqlUser#1@localhost:1521/xepdb1 @/workspaces/starter-oracle-db/module-06-sql/dml-examples.sql
--
-- 前提: setup-tables.sql が完了していること

SET FEEDBACK ON
SET ECHO ON
SET LINESIZE 120
SET PAGESIZE 50

COLUMN name       FORMAT A20
COLUMN dept_id    FORMAT 9,999
COLUMN salary     FORMAT 9,990.00
COLUMN hire_date  FORMAT A12
COLUMN job_title  FORMAT A20

PROMPT
PROMPT === Step 8-1: INSERT（単一行） ===
PROMPT

INSERT INTO employees (emp_id, name, dept_id, salary, hire_date, job_title)
VALUES (101, 'Ichiro', 10, 5200, DATE '2024-04-01', 'Engineer');

INSERT INTO employees (emp_id, name, dept_id, salary, hire_date, job_title)
VALUES (102, 'Jiro', 20, 4300, DATE '2024-04-01', 'Marketer');

-- 挿入後の確認
SELECT emp_id, name, dept_id, salary, hire_date
FROM employees
WHERE emp_id IN (101, 102);

PROMPT
PROMPT === Step 8-2: UPDATE ===
PROMPT

-- Engineering（dept_id=10）の社員の給与を 10% アップする
UPDATE employees SET salary = salary * 1.1
WHERE dept_id = 10;

-- 更新後の確認
SELECT emp_id, name, salary FROM employees
WHERE dept_id = 10
ORDER BY emp_id;

PROMPT
PROMPT === Step 8-3: DELETE ===
PROMPT

-- 給与が未設定の社員を削除する
DELETE FROM employees WHERE salary IS NULL;

-- 削除後の確認
SELECT emp_id, name, dept_id, salary FROM employees
WHERE emp_id = 9;

PROMPT  → 0件が返れば削除成功（Iris を削除した）
PROMPT

PROMPT
PROMPT === Step 8-4: MERGE（Upsert） ===
PROMPT

-- emp_id=102 は既存: UPDATE する
-- emp_id=103 は新規: INSERT する
MERGE INTO employees tgt
USING (
  SELECT 102 emp_id, 'Jiro Updated' name, 20 dept_id, 4800 salary,
         DATE '2024-04-01' hire_date, 'Senior Marketer' job_title FROM dual
  UNION ALL
  SELECT 103 emp_id, 'Saburo' name, 30 dept_id, 3700 salary,
         DATE '2024-06-01' hire_date, 'HR Specialist' job_title FROM dual
) src ON (tgt.emp_id = src.emp_id)
WHEN MATCHED THEN
  UPDATE SET tgt.name = src.name, tgt.salary = src.salary, tgt.job_title = src.job_title
WHEN NOT MATCHED THEN
  INSERT (emp_id, name, dept_id, salary, hire_date, job_title)
  VALUES (src.emp_id, src.name, src.dept_id, src.salary, src.hire_date, src.job_title);

-- MERGE 後の確認
SELECT emp_id, name, dept_id, salary, job_title
FROM employees
WHERE emp_id IN (102, 103)
ORDER BY emp_id;

PROMPT
PROMPT === このセッションの変更を ROLLBACK して元に戻す ===
PROMPT  ※ 実習後に元のデータに戻す場合は ROLLBACK を使う。
PROMPT  ※ COMMIT 済みの変更は ROLLBACK できないため、ここでは ROLLBACK で未コミットの変更のみ取り消す。
PROMPT

ROLLBACK;

-- ROLLBACK 後の確認（INSERT/UPDATE/DELETE/MERGE が取り消されているか）
SELECT COUNT(*) rows_count FROM employees;
PROMPT  → 10行（初期データ）に戻っていれば ROLLBACK 成功

SELECT name, salary FROM employees WHERE emp_id = 1;
PROMPT  → Alice の salary が 5000（UPDATE 前）に戻っていれば成功

EXIT;
