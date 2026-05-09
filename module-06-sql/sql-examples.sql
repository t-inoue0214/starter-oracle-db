-- Module 6 実習: 結合・副問合せ・集合演算・分析関数のサンプル集
-- 使用方法: sqlplus sql_user/SqlUser#1@localhost:1521/xepdb1 @/workspaces/starter-oracle-db/module-06-sql/sql-examples.sql
--
-- 前提: setup-tables.sql が完了していること

SET FEEDBACK ON
SET ECHO ON
SET LINESIZE 120
SET PAGESIZE 50

COLUMN name       FORMAT A20
COLUMN dept_name  FORMAT A20
COLUMN job_title  FORMAT A20
COLUMN product    FORMAT A15
COLUMN hire_str   FORMAT A15
COLUMN grade      FORMAT A10
COLUMN dept       FORMAT A15
COLUMN status     FORMAT A10

PROMPT
PROMPT === Step 2: DUAL テーブルと ROWNUM ===
PROMPT

-- 現在日時と30日後を確認する
SELECT SYSDATE today, SYSDATE + 30 next_month FROM dual;

-- 上位3件の高給与社員を取得する（ROWNUM は副問合せで使う、NULLS LAST で NULL を末尾に）
SELECT emp_id, name, salary
FROM (
  SELECT emp_id, name, salary FROM employees ORDER BY salary DESC NULLS LAST
)
WHERE ROWNUM <= 3;

PROMPT
PROMPT === Step 3: 単一行関数 ===
PROMPT

-- NVL: NULL を 0 に変換、NVL2: NULL かどうかでメッセージを切り替える
SELECT name,
       NVL(salary, 0)               salary,
       NVL2(salary, '給与あり', '未設定') status
FROM employees
ORDER BY salary DESC NULLS LAST;

-- CASE で給与ランクを付ける
SELECT name, salary,
  CASE WHEN salary >= 5000 THEN 'Senior'
       WHEN salary >= 3500 THEN 'Mid'
       WHEN salary IS NOT NULL THEN 'Junior'
       ELSE '未設定'
  END grade
FROM employees
ORDER BY salary DESC NULLS LAST;

-- DECODE で部門 ID を名前に変換する
SELECT name,
       DECODE(dept_id, 10, 'Engineering',
                       20, 'Marketing',
                       30, 'HR',
                       'その他') dept
FROM employees;

-- 日付関数: 入社から何ヶ月か・文字列に変換
SELECT name, hire_date,
       ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) months_worked,
       TO_CHAR(hire_date, 'YYYY"年"MM"月"DD"日"') hire_str
FROM employees
ORDER BY hire_date;

PROMPT
PROMPT === Step 4: GROUP BY / HAVING ===
PROMPT

COLUMN dept_name  FORMAT A20
COLUMN emp_count  FORMAT 9,999 HEADING '人数'
COLUMN avg_salary FORMAT 9,990 HEADING '平均給与'

-- 部門別の人数・平均給与（LEFT JOIN で部門未割り当て社員も含む）
SELECT d.dept_name,
       COUNT(e.emp_id)       emp_count,
       ROUND(AVG(e.salary), 0) avg_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY avg_salary DESC NULLS LAST;

-- 平均給与が 4500 以上の部門のみ表示する（HAVING）
SELECT dept_id, ROUND(AVG(salary), 0) avg_salary
FROM employees
GROUP BY dept_id
HAVING AVG(salary) >= 4500
ORDER BY avg_salary DESC;

PROMPT
PROMPT === Step 5: 結合（JOIN） ===
PROMPT

-- INNER JOIN: 部門が設定されている社員のみ表示する
SELECT e.name, d.dept_name, e.salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.salary DESC;

-- LEFT OUTER JOIN: 部門未割り当て（Iris, Jack）も表示する
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.dept_name NULLS LAST;

-- 3テーブル結合: 社員・部門・注文を一度に取得する
COLUMN emp_name   FORMAT A12
COLUMN dept_name  FORMAT A15
COLUMN product    FORMAT A12
COLUMN quantity   FORMAT 9,999

SELECT e.name emp_name, d.dept_name, p.name product, o.quantity
FROM orders o
JOIN employees   e ON o.emp_id    = e.emp_id
JOIN products    p ON o.product_id = p.product_id
JOIN departments d ON e.dept_id   = d.dept_id
ORDER BY e.name;

PROMPT
PROMPT === Step 6: 副問合せ ===
PROMPT

-- スカラー副問合せ: 平均給与より高い社員を抽出する
SELECT name, salary FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;

-- インラインビュー + ROW_NUMBER(): 各部門の最高給与社員を取得する
SELECT dept_id, name, salary
FROM (
  SELECT dept_id, name, salary,
         ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) rn
  FROM employees
  WHERE dept_id IS NOT NULL
)
WHERE rn = 1
ORDER BY dept_id;

-- EXISTS 相関副問合せ: 注文がある社員が属する部門を表示する
SELECT dept_name FROM departments d
WHERE EXISTS (
  SELECT 1 FROM employees e
  JOIN orders o ON e.emp_id = o.emp_id
  WHERE e.dept_id = d.dept_id
);

PROMPT
PROMPT === Step 7: 集合演算 ===
PROMPT

-- UNION: Engineering または Marketing に属する社員（重複除去）
SELECT name, 'Engineering' dept FROM employees WHERE dept_id = 10
UNION
SELECT name, 'Marketing'   dept FROM employees WHERE dept_id = 20
ORDER BY dept, name;

-- INTERSECT: 給与 > 4500 かつ Engineering に属する社員の emp_id
SELECT emp_id FROM employees WHERE salary > 4500
INTERSECT
SELECT emp_id FROM employees WHERE dept_id = 10;

-- MINUS: 一度も注文していない社員を抽出する
SELECT emp_id, name FROM employees
WHERE emp_id IN (
  SELECT emp_id FROM employees
  MINUS
  SELECT DISTINCT emp_id FROM orders
)
ORDER BY emp_id;

PROMPT
PROMPT === 分析関数（ROW_NUMBER / RANK） ===
PROMPT

COLUMN rank_in_dept FORMAT 9,999 HEADING '部門内順位'

-- 部門内の給与ランキングを付ける
SELECT dept_id, name, salary,
       ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) rank_in_dept
FROM employees
WHERE dept_id IS NOT NULL
ORDER BY dept_id, rank_in_dept;

EXIT;
