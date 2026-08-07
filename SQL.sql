-- Create the database and switch to it
DROP DATABASE IF EXISTS college_db;
CREATE DATABASE college_db;
USE college_db;

-- Create departments table: dept_id auto-increments, dept_name must be unique
CREATE TABLE departments(
    dept_id int primary key auto_increment,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
    hod_name VARCHAR(100) NOT NULL,
    established YEAR DEFAULT 2000
);

-- Create students table with FK to departments; if a department is deleted,
-- dept_id on matching students is set to NULL instead of blocking the delete
CREATE TABLE students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    dept_id INT,
    gpa DECIMAL(4,2) CHECK (gpa BETWEEN 0 AND 10),
    enrolled_on DATE DEFAULT (CURDATE()),
    status ENUM('active','inactive','alumni') DEFAULT 'active',
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE SET NULL
);

-- Drop students entirely (structure + data) and confirm remaining tables
DROP TABLE students;
SHOW TABLES;
DESCRIBE students;


ALTER TABLE students
MODIFY gpa DECIMAL(3,2) CHECK(gpa BETWEEN 0 AND 10);   -- <-- added missing semicolon

DESC students;

-- Create courses table, linked to departments
CREATE TABLE courses(
    course_id int primary key auto_increment,
    course_name VARCHAR(150) NOT NULL,
    dept_id INT,
    credits INT DEFAULT 3,
    foreign key (dept_id) REFERENCES departments(dept_id)
);

-- Create enrollments as a junction table (many-to-many between students and courses)
-- Composite primary key prevents the same student enrolling twice in the same course
CREATE TABLE enrollments(
    student_id INT,
    course_id INT,
    grade CHAR(2),
    semester VARCHAR(20),
    primary key (student_id,course_id),
    foreign key (student_id) REFERENCES students(student_id) ON DELETE CASCADE, -- If a student is deleted from students table corresponding rows are also deleted 
    foreign key (course_id) REFERENCES courses(course_id)
);

-- Add a column, widen it, rename it, then drop it (demonstrates ALTER TABLE variants)
ALTER TABLE students ADD COLUMN phone VARCHAR(15);
describe students;
ALTER TABLE students MODIFY COLUMN phone VARCHAR(20);
ALTER TABLE students RENAME COLUMN phone TO mobile;
ALTER TABLE students DROP COLUMN mobile;

-- Clone the students table structure (LIKE copies columns/indexes, NOT data or foreign keys),
-- empty it instantly with TRUNCATE, inspect its structure, then remove it
CREATE TABLE new_students LIKE students;
TRUNCATE TABLE new_students;
DESC new_students;
DROP TABLE new_students;


-- UPDATE->Modify data in rows , Table data , Change a student’s GPA

-- ALTER TABLE->Modify the table structure , Schema , Add/remove columns, constraints

-- MODIFY->A clause of ALTER TABLE (MySQL) , One column’s definition , Increase a column’s size 

-- Insert a department letting dept_id auto-increment
INSERT INTO departments (dept_name, hod_name, established)
VALUES ('Computational Technologies', 'Dr. Sharma', 2010);

-- Insert a department with an explicit dept_id (allowed, but risks colliding with
-- a future auto-generated id — generally best to let AUTO_INCREMENT handle it)
INSERT INTO departments (dept_id,dept_name, hod_name, established)
VALUES (4,'Computational', 'Dr. Gupta', 2014);

Update departments set dept_id=2 where dept_id=4;
-- Bulk insert multiple departments in a single statement
INSERT INTO departments (dept_name, hod_name, established) VALUES
  ('Computer Science',       'Dr. Iyer',   2005),
  ('Information Technology', 'Dr. Mehta',  2008),
  ('Data Science',           'Dr. Nair',   2018);

SELECT * from departments;

Update departments set dept_id=3 where dept_id=5;
Update departments set dept_id=4 where dept_id=6;
Update departments set dept_id=5 where dept_id=7;


-- Bulk insert students, referencing dept_id values above
INSERT INTO students (name, email, dept_id, gpa) VALUES
  ('Kshitij', 'kt@srm.edu',  1, 8.90),
  ('Aryan',   'a@srm.edu',  4, 7.50),
  ('Priya',   'p@srm.edu',  1, 9.20),
  ('Riya',    'r@srm.edu',  4, 6.80),
  ('Dev',     'd@srm.edu',  5, 8.10);

Truncate table students;
-- TRUNCATE TABLE does not work if the table is referenced by a foreign key.

set sql_safe_updates=0; -- safety mode off
Delete from students;
alter table students auto_increment 1;
set sql_safe_updates=1; -- safety mode on

SELECT * from students;

-- Second "Kshitij" — different email so it's allowed (email is UNIQUE, name is not)
INSERT INTO students (name, email, dept_id, gpa) VALUES
('Kshitij', 'k@srm.edu',  1, 8.90);




UPDATE students
SET gpa=9.5,status='alumni'
WHERE name='Kshitij';


DELETE FROM students WHERE status='active';

-- Aliasing output column names with AS
SELECT name AS student_name, gpa AS grade_point
FROM students;

-- DISTINCT removes duplicate values in the result set
SELECT DISTINCT name FROM students;

-- Delete duplicate rows: for every pair of rows with the same name, delete the
-- one with the LARGER student_id, keeping only the earliest-inserted row
DELETE s1
FROM students s1
JOIN students s2
ON s1.name=s2.name
AND s1.student_id>s2.student_id;

SELECT name AS n ,student_id AS s
FROM students WHERE gpa>8;


-- Multi-column ORDER BY: primary sort by name (A-Z), then by gpa (high to low) within ties
SELECT name,gpa FROM students
ORDER BY gpa DESC , name ASC ;

update students set gpa = 9.00 where student_id=7;
-- ============================================
-- GROUP BY + HAVING + AGGREGATE FUNCTIONS
-- using college_db schema
-- ============================================
INSERT INTO courses (course_name, dept_id, credits) VALUES
  ('Data Structures',      1, 4),
  ('Database Systems',     1, 4),
  ('Machine Learning',     5, 3),
  ('Web Development',      4, 3),
  ('Operating Systems',    1, 4);
 
SELECT * FROM courses;

-- INSERT INTO ... SELECT, where the data being inserted is generated by another query instead of being typed directly.
INSERT INTO enrollments (student_id, course_id, grade, semester)
SELECT s.student_id, c.course_id, v.grade, v.semester
FROM (
    SELECT 'kt@srm.edu' AS email, 'Data Structures' AS course, 'A'  AS grade, 'Fall 2025' AS semester
    UNION ALL SELECT 'kt@srm.edu', 'Database Systems',  'A-', 'Fall 2025'
    UNION ALL SELECT 'a@srm.edu',  'Web Development',   'B+', 'Fall 2025'
    UNION ALL SELECT 'p@srm.edu',  'Data Structures',   'A',  'Fall 2025'
    UNION ALL SELECT 'p@srm.edu',  'Machine Learning',  'A',  'Fall 2025'
    UNION ALL SELECT 'r@srm.edu',  'Operating Systems', 'B',  'Fall 2025'
    UNION ALL SELECT 'd@srm.edu',  'Machine Learning',  'B+', 'Fall 2025'
) v
JOIN students s ON s.email = v.email
JOIN courses c  ON c.course_name = v.course;

select * from enrollments;

-- 1. Basic aggregates (no grouping) — overall stats across all students
SELECT
    COUNT(*) AS total_students,
    AVG(gpa) AS avg_gpa,
    MAX(gpa) AS highest_gpa,
    MIN(gpa) AS lowest_gpa,
    SUM(gpa) AS gpa_sum
FROM students;


-- 2. GROUP BY — average GPA per department
SELECT d.dept_name, AVG(s.gpa) AS avg_gpa
FROM students s
JOIN departments d ON s.dept_id = d.dept_id
GROUP BY d.dept_name;


-- 3. GROUP BY — count of students per department
-- LEFT JOIN so departments with 0 students still show up (with count 0)
SELECT d.dept_name, COUNT(s.student_id) AS student_count
FROM departments d LEFT JOIN students s 
ON d.dept_id = s.dept_id
GROUP BY d.dept_name;


-- 4. HAVING — filter groups AFTER aggregation
-- (WHERE can't be used here because COUNT() doesn't exist until grouping happens)
-- Departments with MORE THAN 1 student
SELECT d.dept_name, COUNT(s.student_id) AS student_count
FROM departments d
JOIN students s ON d.dept_id = s.dept_id
GROUP BY d.dept_name
HAVING student_count > 1;


-- 5. WHERE + GROUP BY + HAVING together
-- WHERE filters rows first (only active students), THEN grouping/aggregation happens,
-- THEN HAVING filters the resulting groups
-- The average GPA of active students in each department, but only for departments whose average GPA is greater than 7.5
SELECT d.dept_name, AVG(s.gpa) AS avg_gpa
FROM students s
JOIN departments d ON s.dept_id = d.dept_id
WHERE s.status = 'active'
GROUP BY d.dept_name
HAVING AVG(s.gpa) > 7.5;


-- 6. Departments with the highest average GPA first
SELECT d.dept_name, AVG(s.gpa) AS avg_gpa
FROM students s
JOIN departments d ON s.dept_id = d.dept_id
GROUP BY d.dept_name
ORDER BY avg_gpa DESC;


-- 7. Grouping across the 3-table join — average grade count per course
-- (counts how many enrollments exist per course, across all students)
SELECT c.course_name, COUNT(e.student_id) AS enrolled_count
FROM courses c LEFT JOIN enrollments e 
ON c.course_id = e.course_id
GROUP BY c.course_name
ORDER BY enrolled_count DESC;

desc enrollments;

-- 8. Multiple grouping columns — student count per department PER status
-- (e.g., how many active vs alumni students in each department)
SELECT d.dept_name, s.status, COUNT(*) AS count
FROM students s
JOIN departments d ON s.dept_id = d.dept_id
GROUP BY d.dept_name, s.status;


-- 9. COUNT(*) vs COUNT(column) — classic interview distinction
-- COUNT(*) counts all rows including NULLs; COUNT(dept_id) skips NULL dept_id rows
SELECT
    COUNT(*) AS all_rows,
    COUNT(dept_id) AS rows_with_dept
FROM students;


-- 10. Departments that have NO students at all (HAVING with COUNT = 0)
SELECT d.dept_name, COUNT(s.student_id) AS student_count
FROM departments d
LEFT JOIN students s ON d.dept_id = s.dept_id
GROUP BY d.dept_name
HAVING student_count = 0;


-- ============================================
-- SAME QUERIES, WRITTEN WITH RIGHT JOIN / FULL OUTER JOIN
-- (RIGHT JOIN is just LEFT JOIN with the tables swapped —
--  shown here so you're comfortable reading/writing both directions)
-- ============================================

-- 11. RIGHT JOIN version of query #3 — student count per department
-- departments is now on the RIGHT, so "ALL departments, even with 0 students" still holds
SELECT d.dept_name, COUNT(s.student_id) AS student_count
FROM students s
RIGHT JOIN departments d ON s.dept_id = d.dept_id
GROUP BY d.dept_name;


-- 12. RIGHT JOIN + HAVING — departments with 0 students (equivalent to query #10,
-- but written with RIGHT JOIN instead of LEFT JOIN)
SELECT d.dept_name, COUNT(s.student_id) AS student_count
FROM students s
RIGHT JOIN departments d ON s.dept_id = d.dept_id
GROUP BY d.dept_name
HAVING COUNT(s.student_id) = 0;


-- 13. FULL OUTER JOIN version — average GPA per department, including:
--   - departments with no students (avg_gpa will be NULL)
--   - students with no valid department (dept_name will be NULL)
-- MySQL has no native FULL JOIN, so emulate with LEFT JOIN UNION RIGHT JOIN
SELECT d.dept_name, AVG(s.gpa) AS avg_gpa, COUNT(s.student_id) AS student_count
FROM students s
LEFT JOIN departments d ON s.dept_id = d.dept_id
GROUP BY d.dept_name
UNION
SELECT d.dept_name, AVG(s.gpa) AS avg_gpa, COUNT(s.student_id) AS student_count
FROM students s
RIGHT JOIN departments d ON s.dept_id = d.dept_id
GROUP BY d.dept_name;

-- Postgres / SQL Server / Oracle (native FULL JOIN, no UNION trick needed):
-- SELECT d.dept_name, AVG(s.gpa) AS avg_gpa, COUNT(s.student_id) AS student_count
-- FROM students s
-- FULL JOIN departments d ON s.dept_id = d.dept_id
-- GROUP BY d.dept_name;


-- 14. Quick mental model for choosing LEFT vs RIGHT vs FULL vs INNER:
--   INNER JOIN  -> only rows that match in both tables
--   LEFT JOIN   -> all rows from the table BEFORE "JOIN", matched or not
--   RIGHT JOIN  -> all rows from the table AFTER "JOIN", matched or not
--   FULL JOIN   -> all rows from both tables, matched or not
-- In practice, most people avoid RIGHT JOIN entirely and just rewrite it as a
-- LEFT JOIN with the table order swapped (query #11 IS query #3, just flipped) —
-- but you should be able to read/write both for interviews.


-- ============================================
-- SUBQUERIES — using college_db schema
-- ============================================

-- 1. Scalar subquery — students with GPA above the overall average
SELECT name, gpa
FROM students
WHERE gpa > (SELECT AVG(gpa) FROM students);


-- 2. Scalar subquery in SELECT list — show each student's gpa alongside the overall average
SELECT name, gpa, (SELECT AVG(gpa) FROM students) AS overall_avg_gpa
FROM students;


-- 3. Correlated subquery — students whose GPA is above their OWN department's average
-- (runs once per outer row, using that row's dept_id)
SELECT s.name, s.gpa, s.dept_id
FROM students s
WHERE s.gpa > (
    SELECT AVG(s2.gpa) FROM students s2 WHERE s2.dept_id = s.dept_id
);


-- 4. IN — students belonging to departments established after 2010
SELECT name, dept_id
FROM students
WHERE dept_id IN (SELECT dept_id FROM departments WHERE established > 2010);


-- 5. NOT IN — students NOT enrolled in any course
-- (careful: NOT IN breaks if the subquery returns a NULL — see EXISTS version below for a safer approach)
SELECT name
FROM students
WHERE student_id NOT IN (SELECT student_id FROM enrollments WHERE student_id IS NOT NULL);


-- 6. EXISTS — departments that have at least one student
SELECT d.dept_name
FROM departments d
WHERE EXISTS (SELECT 1 FROM students s WHERE s.dept_id = d.dept_id);


-- 7. NOT EXISTS — departments with NO students (safer/faster than NOT IN, and NULL-safe)
SELECT d.dept_name
FROM departments d
WHERE NOT EXISTS (SELECT 1 FROM students s WHERE s.dept_id = d.dept_id);


-- 8. NOT EXISTS — students not enrolled in any course (NULL-safe rewrite of query 5)
SELECT s.name
FROM students s
WHERE NOT EXISTS (SELECT 1 FROM enrollments e WHERE e.student_id = s.student_id);


-- 9. Subquery in FROM clause (derived table) — average GPA per department,
-- then filter departments above 8.0 without using HAVING
SELECT * FROM (
    SELECT d.dept_name, AVG(s.gpa) AS avg_gpa
    FROM students s
    JOIN departments d ON s.dept_id = d.dept_id
    GROUP BY d.dept_name
) dept_avgs
WHERE avg_gpa > 8.0;


-- 10. Subquery with course + enrollment — students enrolled in 'Data Structures'
SELECT name FROM students
WHERE student_id IN (
    SELECT student_id FROM enrollments
    WHERE course_id = (SELECT course_id FROM courses WHERE course_name = 'Data Structures')
);


-- 11. ANY / ALL — students with GPA higher than ALL students in Data Science dept
SELECT name, gpa FROM students
WHERE gpa > ALL (
    SELECT gpa FROM students s
    JOIN departments d ON s.dept_id = d.dept_id
    WHERE d.dept_name = 'Data Science'
);

-- Students with GPA higher than AT LEAST ONE student in Data Science dept
SELECT name, gpa FROM students
WHERE gpa > ANY (
    SELECT gpa FROM students s
    JOIN departments d ON s.dept_id = d.dept_id
    WHERE d.dept_name = 'Data Science'
);


-- Quick-fire distinctions for interviews:
--   IN vs EXISTS      -> IN materializes the full subquery result and compares;
--                         EXISTS just checks "does at least one row match" and stops early.
--                         Prefer EXISTS for large subquery result sets, and always for
--                         NOT IN/NOT EXISTS since NOT IN silently returns no rows if the
--                         subquery contains any NULL.
--   Scalar vs Correlated -> Scalar subquery runs ONCE, independent of the outer query.
--                            Correlated subquery runs ONCE PER OUTER ROW (references the outer row).
--   Subquery vs JOIN   -> JOIN can return duplicate rows if there are multiple matches;
--                         subqueries with EXISTS/IN can't, since they only ask a yes/no question.

-- ================================================================
-- WINDOW FUNCTIONS — EXPLAINED FROM SCRATCH
-- ================================================================
-- WHAT IS A WINDOW FUNCTION?
-- A normal aggregate function (like AVG, SUM, COUNT) takes many rows and
-- collapses them into ONE row. GROUP BY does this -- you lose the individual rows.
--
-- A WINDOW FUNCTION does the calculation across a group of rows too, but
-- it does NOT collapse them -- every original row stays, and you just get an
-- extra column showing the calculated value for that row's "window" (group).
--
-- The general syntax is always:
--     <function>() OVER (PARTITION BY <column> ORDER BY <column>)
--
-- PARTITION BY  = "restart the calculation for each group"
--                 (like GROUP BY, but doesn't merge rows -- just resets the window)
-- ORDER BY      = "in what order should rows be considered within each partition"
--                 (needed for ranking, running totals, LAG/LEAD -- not needed for
--                  simple per-group aggregates)
-- If you omit PARTITION BY entirely, the "window" is the whole table.
-- ================================================================


-- 1. ROW_NUMBER / RANK / DENSE_RANK -- three ways to number/rank rows
--
-- Imagine students sorted by GPA (highest first) within their own department.
-- These three functions all assign a position number, but handle TIES differently:
--
--   ROW_NUMBER() -> always unique, no ties allowed: 1, 2, 3, 4, 5...
--                   (if two students have the same GPA, one is arbitrarily 1st)
--
--   RANK()       -> ties get the SAME number, but the next number SKIPS ahead
--                   e.g. if 2 students tie for 1st: 1, 1, 3, 4  (no rank "2" given out)
--
--   DENSE_RANK() -> ties get the SAME number, but the next number does NOT skip
--                   e.g. if 2 students tie for 1st: 1, 1, 2, 3  (rank "2" is used)
--
-- PARTITION BY s.dept_id  -> restart numbering for every new department
-- ORDER BY s.gpa DESC     -> rank highest GPA first within each department
SELECT s.name, d.dept_name, s.gpa,
    ROW_NUMBER() OVER (PARTITION BY s.dept_id ORDER BY s.gpa DESC) AS rn,
    RANK()       OVER (PARTITION BY s.dept_id ORDER BY s.gpa DESC) AS rnk,
    DENSE_RANK() OVER (PARTITION BY s.dept_id ORDER BY s.gpa DESC) AS drnk
FROM students s
JOIN departments d ON s.dept_id = d.dept_id;


-- 2. Top student per department (highest GPA in each dept)
--
-- Window functions CANNOT be used directly in a WHERE clause (the database
-- calculates WHERE before it calculates window functions). So the pattern is:
-- Step 1: wrap the window-function query in a subquery (give it an alias, "ranked")
-- Step 2: filter on the calculated column (rn = 1) from OUTSIDE, in the outer SELECT
SELECT * FROM (
    SELECT s.name, d.dept_name, s.gpa,
        ROW_NUMBER() OVER (PARTITION BY s.dept_id ORDER BY s.gpa DESC) AS rn
    FROM students s
    JOIN departments d ON s.dept_id = d.dept_id
) ranked
WHERE rn = 1;   -- rn = 1 means "top GPA in this department"


-- 3. 2nd highest GPA overall (classic interview question)
--
-- Same wrap-in-a-subquery pattern as above, but no PARTITION BY this time --
-- so it ranks ALL students together (one single window = the whole table).
-- Uses DENSE_RANK so that if 2 students tie for 1st place, the 2nd highest
-- UNIQUE gpa value still gets rank 2 (not rank 3).
SELECT DISTINCT gpa FROM (
    SELECT gpa, DENSE_RANK() OVER (ORDER BY gpa DESC) AS drnk
    FROM students
) t
WHERE drnk = 2;


-- 4. 2nd highest GPA PER department
-- Same idea as #3, but with PARTITION BY dept_id added -- so the ranking
-- restarts fresh for every department instead of ranking everyone together.
SELECT dept_id, name, gpa FROM (
    SELECT dept_id, name, gpa,
        DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY gpa DESC) AS drnk
    FROM students
) t
WHERE drnk = 2;


-- 5. Running total -- a "cumulative sum" that grows as you go down the rows
--
-- Think of it like a bank statement: each row shows the balance INCLUDING
-- everything before it, not just that row's own amount.
-- SUM(gpa) OVER (ORDER BY student_id) means: "for each row, sum up gpa from
-- the very first row up to and including THIS row" (default window frame
-- behavior when ORDER BY is used without PARTITION BY).
SELECT student_id, name, gpa,
    SUM(gpa) OVER (ORDER BY student_id) AS running_gpa_total
FROM students;


-- 6. Running average within each department
-- Same running-total idea as #5, but PARTITION BY s.dept_id makes the
-- running average restart from zero at the start of each new department.
SELECT s.name, d.dept_name, s.gpa,
    AVG(s.gpa) OVER (PARTITION BY s.dept_id ORDER BY s.student_id) AS running_avg
FROM students s
JOIN departments d ON s.dept_id = d.dept_id;


-- 7. LAG / LEAD -- look at the PREVIOUS or NEXT row's value, from the current row
--
-- Normally in SQL, one row can't "see" another row's data. LAG/LEAD break that rule:
--   LAG(column, 1)  -> pulls the value from 1 row BEFORE the current row
--   LEAD(column, 1) -> pulls the value from 1 row AFTER the current row
-- The "1" means "1 row back/forward" -- you could use 2 to look further back.
-- Useful for comparisons like "did this month's sales go up or down vs last month".
SELECT student_id, name, gpa,
    LAG(gpa, 1)  OVER (ORDER BY student_id) AS prev_student_gpa,
    LEAD(gpa, 1) OVER (ORDER BY student_id) AS next_student_gpa
FROM students;


-- 8. LAG within partition -- same idea as #7, but PARTITION BY dept_id means
-- "previous row" only looks within the SAME department, not the whole table.
-- Ordered by gpa DESC, so this shows "the next lower GPA in this department".
SELECT s.name, d.dept_name, s.gpa,
    LAG(s.gpa, 1) OVER (PARTITION BY s.dept_id ORDER BY s.gpa DESC) AS next_lower_gpa_in_dept
FROM students s
JOIN departments d ON s.dept_id = d.dept_id;


-- 9. NTILE(n) -- split all rows into "n" equal-ish sized buckets
-- NTILE(4) divides students into 4 groups based on GPA rank: group 1 = top
-- quarter of GPAs, group 4 = bottom quarter. Common for percentile-style analysis
-- ("which quartile does this student fall into?").
SELECT name, gpa,
    NTILE(4) OVER (ORDER BY gpa DESC) AS gpa_quartile
FROM students;


-- 10. FIRST_VALUE / LAST_VALUE -- grab the first or last value within a window,
-- and repeat it on EVERY row in that window (unlike LAG/LEAD which only looks
-- 1 row away, this looks at the very first/last row of the whole partition).
SELECT s.name, d.dept_name, s.gpa,
    FIRST_VALUE(s.gpa) OVER (PARTITION BY s.dept_id ORDER BY s.gpa DESC) AS dept_top_gpa,
    LAST_VALUE(s.gpa)  OVER (
        PARTITION BY s.dept_id ORDER BY s.gpa DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS dept_lowest_gpa
FROM students s
JOIN departments d ON s.dept_id = d.dept_id;
-- WHY does LAST_VALUE need that extra "ROWS BETWEEN..." line but FIRST_VALUE doesn't?
-- By default, a window with ORDER BY only "sees" rows from the start of the
-- partition up to the CURRENT row (it doesn't know about rows below it yet).
-- So LAST_VALUE would just keep returning the current row's own gpa, not the
-- true lowest. "ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING" tells
-- SQL "let this window see EVERY row in the partition, not just up to current row".


-- ================================================================
-- QUICK-FIRE DISTINCTIONS (common interview questions)
-- ================================================================
-- RANK vs DENSE_RANK:
--    RANK leaves a gap after ties (1,1,3). DENSE_RANK does not (1,1,2).
--
-- Window function vs GROUP BY:
--    GROUP BY MERGES rows into one row per group -- you lose row-level detail.
--    Window functions KEEP every row and just attach a calculated value to each.
--    Rule of thumb: if you need to see individual rows AND a group calculation
--    side by side, you need a window function, not GROUP BY.
--
-- PARTITION BY vs GROUP BY:
--    Both "group" rows conceptually, but PARTITION BY does NOT reduce the row
--    count (like GROUP BY does) -- it just tells the window function where to
--    "restart" its calculation.


-- ================================================================
-- VIEWS -- EXPLAINED FROM SCRATCH
-- ================================================================
-- WHAT IS A VIEW?
-- A view is a SAVED QUERY that behaves like a virtual table. It does NOT
-- store data of its own -- every time you SELECT from a view, the database
-- runs the underlying query fresh and gives you the current results.
--
-- Why use one?
--   1. Simplification -- hide a complicated JOIN behind a simple name, so
--      you (or teammates) can just "SELECT * FROM easy_view" instead of
--      rewriting the same 3-table join every time.
--   2. Security -- give someone access to a view that only shows certain
--      columns/rows, without giving them access to the full underlying table.
--   3. Consistency -- if 5 different reports use the same "active students"
--      logic, defining it once as a view means you only update it in one place.
-- ================================================================


-- 1. CREATE VIEW -- save a query as a reusable virtual table
-- This view hides the join between students and departments behind one name.
CREATE VIEW student_details AS
SELECT s.student_id, s.name, s.gpa, s.status, d.dept_name
FROM students s
JOIN departments d ON s.dept_id = d.dept_id;

-- Now you can query it exactly like a table:
SELECT * FROM student_details;
SELECT * FROM student_details WHERE gpa > 8;


-- 2. A view can wrap aggregation too -- e.g., department-level stats
CREATE VIEW dept_stats AS
SELECT d.dept_name, COUNT(s.student_id) AS student_count, AVG(s.gpa) AS avg_gpa
FROM departments d
LEFT JOIN students s ON d.dept_id = s.dept_id
GROUP BY d.dept_name;

SELECT * FROM dept_stats;
SELECT * FROM dept_stats WHERE student_count = 0;


-- 3. UPDATE (modify) a view's definition
-- You don't "edit" a view like a normal statement -- you REPLACE its whole
-- definition. CREATE OR REPLACE VIEW overwrites it with a new query.
-- Here we add the student's status into student_details.
CREATE OR REPLACE VIEW student_details AS
SELECT s.student_id, s.name, s.gpa, s.status, s.enrolled_on, d.dept_name
FROM students s
JOIN departments d ON s.dept_id = d.dept_id;

SELECT * FROM student_details;


-- 4. Updating data THROUGH a simple view
-- If a view is "simple enough" (comes from one table, no GROUP BY/JOIN/aggregate),
-- you can actually INSERT/UPDATE/DELETE through it, and it changes the real table.
CREATE VIEW active_students AS
SELECT student_id, name, gpa, status
FROM students
WHERE status = 'active';

-- This actually updates the real "students" table, not just the view:
UPDATE active_students SET gpa = 9.0 WHERE student_id = 1;

-- NOTE: dept_stats and the joined student_details CANNOT be updated this way --
-- views built on JOINs, GROUP BY, or aggregates are read-only in MySQL.


-- 5. RENAME a view
-- MySQL has no direct "RENAME VIEW" command -- you rename by creating a
-- new view with a new name from the old one's definition, then dropping the old one.
CREATE VIEW student_overview AS SELECT * FROM student_details;
DROP VIEW student_details;

-- (In SQL Server, you'd use: EXEC sp_rename 'student_details', 'student_overview';)


-- 6. DROP VIEW -- remove a view entirely (doesn't touch the underlying tables/data)
DROP VIEW student_overview;
DROP VIEW dept_stats;
DROP VIEW active_students;


-- 7. See what views exist in your database
SHOW FULL TABLES IN college_db WHERE TABLE_TYPE = 'VIEW';


-- ================================================================
-- QUICK-FIRE DISTINCTIONS (common interview questions)
-- ================================================================
-- View vs Table:
--    A table physically stores data on disk. A view stores only a QUERY --
--    it recalculates its result every time you use it, always showing current data.
--
-- View vs Materialized View:
--    A regular view recalculates every time (always fresh, but can be slower on
--    complex queries). A MATERIALIZED view (not natively in MySQL, but exists in
--    Postgres/Oracle) actually stores the result physically like a table, so it's
--    faster to read but can go stale until manually refreshed.
--
-- Can you always update data through a view?
--    No -- only "simple" views (single table, no JOIN/GROUP BY/aggregate/DISTINCT)
--    are updatable. Complex views are read-only.


-- ================================================================
-- INDEXES -- EXPLAINED FROM SCRATCH
-- ================================================================
-- WHAT IS AN INDEX?
-- Without an index, to find a row the database must scan EVERY row in the
-- table one by one (a "full table scan"). Slow once tables get large.
--
-- An index is a separate, sorted lookup structure built on one or more
-- columns -- like the index at the back of a textbook. Instead of reading
-- every page to find "photosynthesis", you jump to the index, find the
-- page number, and go straight there. A DB index works the same way: it
-- lets the DB jump straight to matching rows instead of scanning everything.
--
-- TRADE-OFF: indexes make READS (SELECT/WHERE/JOIN/ORDER BY) faster, but
-- make WRITES (INSERT/UPDATE/DELETE) slightly slower -- because every time
-- you change data, the index has to be updated too, not just the table.
-- So you don't index every column "just in case" -- only columns you
-- actually filter/sort/join on frequently.
-- ================================================================


-- 1. CREATE INDEX -- speed up lookups on a column you query often
-- Your students table already filters/joins on dept_id constantly (every
-- JOIN to departments uses it) -- this is a great index candidate.
CREATE INDEX idx_students_dept ON students(dept_id);

-- Index on gpa, since you frequently filter/sort by it (WHERE gpa > 8, ORDER BY gpa)
CREATE INDEX idx_students_gpa ON students(gpa);

-- Composite (multi-column) index -- useful when you filter/sort by BOTH
-- columns together often, e.g. WHERE dept_id = X ORDER BY gpa DESC
CREATE INDEX idx_students_dept_gpa ON students(dept_id, gpa);


-- 2. UNIQUE INDEX -- like a normal index, but also enforces "no duplicates allowed"
-- (Note: PRIMARY KEY and UNIQUE constraints already auto-create indexes behind
-- the scenes -- this is for adding uniqueness+speed to a column that ISN'T
-- already a primary/unique key. Your email column is already UNIQUE, so MySQL
-- already made an index for it automatically -- this is just to show the syntax.)
CREATE UNIQUE INDEX idx_dept_name_unique ON departments(dept_name);


-- 3. SHOW indexes on a table -- see what indexes currently exist
SHOW INDEXES FROM students;
SHOW INDEXES FROM departments;


-- 4. EXPLAIN -- see whether a query is actually USING an index or doing a full scan
-- Run this before and after creating idx_students_gpa (query #1) to see the
-- difference: look at the "type" and "key" columns in the output.
-- "key" = NULL means no index was used (full table scan).
-- "key" = idx_students_gpa means the index WAS used.
EXPLAIN SELECT * FROM students WHERE gpa > 8;


-- 5. DROP INDEX -- remove an index (e.g., if it's not actually helping, or the
-- table is small enough that the write-speed cost isn't worth it)
DROP INDEX idx_students_dept_gpa ON students;
DROP INDEX idx_dept_name_unique ON departments;


-- ================================================================
-- QUICK-FIRE DISTINCTIONS (common interview questions)
-- ================================================================
-- CLUSTERED vs NON-CLUSTERED index:
--   CLUSTERED index -> physically determines the ORDER data is stored on disk.
--       There can be only ONE clustered index per table (usually the
--       PRIMARY KEY automatically becomes this in MySQL/InnoDB).
--       Think of it like a phone book -- the data itself IS sorted by the index.
--   NON-CLUSTERED index -> a SEPARATE structure that just points to where the
--       actual row lives (like the textbook index pointing to a page number).
--       A table can have MANY non-clustered indexes.
--
-- Why not index every column?
--   Every index speeds up reads but slows down every INSERT/UPDATE/DELETE
--   (since the index must also be updated), and takes up extra disk space.
--   Only index columns you filter (WHERE), join (ON), or sort (ORDER BY) on often.
--
-- Does an index help with LIKE '%something%'?
--   No -- a leading wildcard (%something) can't use a normal index, since the
--   index is sorted and a search starting with "anything before this" can't
--   jump to a starting point. LIKE 'something%' (wildcard only at the END)
--   CAN use an index.


-- ================================================================
-- TRIGGERS -- EXPLAINED FROM SCRATCH
-- ================================================================
-- WHAT IS A TRIGGER?
-- A trigger is a block of code that automatically runs by itself whenever
-- a specific event happens on a table -- INSERT, UPDATE, or DELETE. You
-- never call a trigger directly; the database fires it for you.
--
-- Think of it like a smoke alarm: you don't manually turn it on when
-- there's a fire -- it's wired to react automatically the moment smoke
-- (the "event") is detected.
--
-- Two timing options:
--   BEFORE -> runs before the change is actually saved (good for validating
--             or modifying the data before it's written)
--   AFTER  -> runs after the change is saved (good for logging, or updating
--             a different table as a side effect)
--
-- Inside a trigger, you get special row references:
--   NEW.column -> the new value being inserted/updated (not available in DELETE)
--   OLD.column -> the value before the change (not available in INSERT)
-- ================================================================


-- 1. First, a log table to record changes (triggers commonly write to
-- a separate audit/log table)
CREATE TABLE gpa_change_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    old_gpa DECIMAL(4,2),
    new_gpa DECIMAL(4,2),
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- 2. AFTER UPDATE trigger -- automatically log every GPA change
-- MySQL requires DELIMITER changes for triggers because the trigger body
-- itself contains semicolons, and we need MySQL to not stop reading at the
-- first one.
DELIMITER //

CREATE TRIGGER trg_log_gpa_change
AFTER UPDATE ON students
FOR EACH ROW
BEGIN
    IF OLD.gpa <> NEW.gpa THEN
        INSERT INTO gpa_change_log(student_id, old_gpa, new_gpa)
        VALUES (OLD.student_id, OLD.gpa, NEW.gpa);
    END IF;
END //

DELIMITER ;

-- Test it: update a GPA, then check the log table
UPDATE students SET gpa = 9.9 WHERE student_id = 1;
SELECT * FROM gpa_change_log;


-- 3. BEFORE INSERT trigger -- validate/clean data before it's saved
-- Example: automatically force status to 'active' if someone inserts a
-- student without specifying one as NULL (even though your table already
-- has DEFAULT 'active', this shows the BEFORE-trigger validation pattern).
DELIMITER //

CREATE TRIGGER trg_check_gpa_range
BEFORE INSERT ON students
FOR EACH ROW
BEGIN
    IF NEW.gpa > 10 THEN
        SET NEW.gpa = 10.00;   -- clamp instead of rejecting, just as an example
    END IF;
END //

DELIMITER ;


-- 4. AFTER DELETE trigger -- log when a student is removed
DELIMITER //

CREATE TRIGGER trg_log_student_delete
AFTER DELETE ON students
FOR EACH ROW
BEGIN
    INSERT INTO gpa_change_log(student_id, old_gpa, new_gpa)
    VALUES (OLD.student_id, OLD.gpa, NULL);   -- new_gpa NULL signals "row deleted"
END //

DELIMITER ;


-- 5. SHOW triggers that exist in the database
SHOW TRIGGERS;
SHOW TRIGGERS WHERE `Table` = 'students';


-- 6. DROP TRIGGER -- remove a trigger
DROP TRIGGER trg_check_gpa_range;
DROP TRIGGER trg_log_student_delete;
DROP TRIGGER trg_log_gpa_change;


-- ================================================================
-- WHY THE "DELIMITER //" THING?
-- ================================================================
-- Normally MySQL treats ";" as "end of statement, run it now". But a
-- trigger's BODY (between BEGIN and END) needs its OWN semicolons inside
-- it without MySQL cutting it short. So we temporarily tell MySQL "treat //
-- as the end-of-statement marker instead of ;" just for defining the
-- trigger, then switch back to normal ";" afterward with "DELIMITER ;".
-- This is a MySQL-specific quirk -- Postgres/SQL Server don't need this.


-- ================================================================
-- QUICK-FIRE DISTINCTIONS (common interview questions)
-- ================================================================
-- BEFORE vs AFTER trigger:
--   BEFORE -> can still modify NEW.column values before they're saved
--             (e.g., validation, auto-correction)
--   AFTER  -> data is already saved; used for side effects like logging or
--             updating another table (can't modify the row anymore)
--
-- Trigger vs Stored Procedure:
--   Trigger fires AUTOMATICALLY on an event (INSERT/UPDATE/DELETE) -- you
--   never call it yourself.
--   Stored Procedure must be called EXPLICITLY (CALL my_procedure()) --
--   it never runs on its own.
--
-- When to avoid triggers:
--   Triggers run silently in the background, which can make debugging
--   harder (an UPDATE might have hidden side effects you forget about).
--   Overusing them can also hurt write performance since every INSERT/
--   UPDATE/DELETE now does extra work behind the scenes.


-- ================================================================
-- TRANSACTIONS -- EXPLAINED FROM SCRATCH
-- ================================================================
-- WHAT IS A TRANSACTION?
-- A transaction groups multiple SQL statements into ONE unit of work.
-- Either ALL of them succeed and get saved together, or if something goes
-- wrong partway through, NONE of them get saved -- it's all-or-nothing.
--
-- Classic example: transferring money between two bank accounts.
--   Step 1: subtract 500 from Account A
--   Step 2: add 500 to Account B
-- If step 1 succeeds but step 2 fails (e.g., app crashes), you'd have
-- money vanish into thin air -- 500 gone from A, never arrived at B.
-- A transaction prevents this: if step 2 fails, step 1 is undone too.
--
-- Key commands:
--   START TRANSACTION / BEGIN -> marks the start of the group
--   COMMIT                    -> save everything permanently
--   ROLLBACK                  -> undo everything back to before START TRANSACTION
--   SAVEPOINT                 -> a "checkpoint" you can roll back to
--                                 WITHOUT undoing the entire transaction
-- ================================================================


-- 1. Basic transaction -- enroll a student in a course
-- (both the enrollment AND a hypothetical "seats_taken" update happen together)
START TRANSACTION;

INSERT INTO enrollments (student_id, course_id, grade, semester)
VALUES (1, 3, NULL, 'Spring 2026');

UPDATE courses SET credits = credits WHERE course_id = 1;  -- placeholder for a real side-effect

COMMIT;   -- both statements are now permanently saved together


-- 2. ROLLBACK -- undo everything if something looks wrong
START TRANSACTION;

UPDATE students SET gpa = gpa - 1 WHERE student_id = 1;

-- imagine you check something here and realize this was a mistake:
ROLLBACK;   -- the gpa update above is undone completely, as if it never ran

SELECT gpa FROM students WHERE student_id = 1;   -- confirms gpa is back to original


-- 3. SAVEPOINT -- roll back PART of a transaction, not all of it
START TRANSACTION;

UPDATE students SET gpa = 8.5 WHERE student_id = 1;
SAVEPOINT after_first_update;

UPDATE students SET gpa = 2.0 WHERE student_id = 2;   -- oops, mistake

ROLLBACK TO after_first_update;
-- student_id 1's update (gpa 8.5) is KEPT.
-- student_id 2's update (gpa 2.0) is UNDONE, since it happened after the savepoint.

COMMIT;   -- saves whatever remains after the rollback-to-savepoint


-- 4. Transaction that should fail and roll back automatically on error
-- Example: inserting an enrollment for a course_id that doesn't exist
-- would violate the FOREIGN KEY constraint and error out --
-- wrap it in a transaction so nothing partial gets saved.
START TRANSACTION;

INSERT INTO enrollments (student_id, course_id, grade, semester)
VALUES (1, 9999, NULL, 'Spring 2026');   -- 9999 doesn't exist -> this line errors

-- If the INSERT above fails, run ROLLBACK manually (MySQL does NOT
-- auto-rollback the whole transaction by default -- only that one
-- statement fails; you must explicitly decide to rollback or continue):
ROLLBACK;


-- 5. Checking/changing autocommit mode
-- By default, MySQL runs in "autocommit" mode -- EVERY single statement is
-- its own mini-transaction, committed instantly. START TRANSACTION
-- temporarily turns autocommit off until you COMMIT or ROLLBACK.
SELECT @@autocommit;        -- 1 = autocommit ON (default), 0 = OFF
SET autocommit = 0;         -- now every statement needs an explicit COMMIT
SET autocommit = 1;         -- back to default behavior


-- ================================================================
-- QUICK-FIRE DISTINCTIONS (common interview questions)
-- ================================================================
-- COMMIT vs ROLLBACK:
--   COMMIT   -> permanently saves all changes made since START TRANSACTION
--   ROLLBACK -> undoes all changes made since START TRANSACTION (or since a SAVEPOINT)
--
-- Why do transactions matter? -> ACID properties:
--   Atomicity   -> all statements in the transaction succeed, or none do
--   Consistency -> the database moves from one valid state to another
--                  (constraints like FK/CHECK are never left violated)
--   Isolation   -> transactions running at the same time don't interfere
--                  with each other's uncommitted changes
--   Durability  -> once COMMIT happens, the data survives even a crash
--                  right afterward
--
-- SAVEPOINT vs full ROLLBACK:
--   Full ROLLBACK undoes the ENTIRE transaction back to START TRANSACTION.
--   ROLLBACK TO <savepoint> only undoes statements AFTER that savepoint,
--   keeping everything before it.

-- ================================================================
-- UNION / INTERSECT / EXCEPT -- EXPLAINED FROM SCRATCH
-- ================================================================
-- WHAT ARE SET OPERATIONS?
-- Joins combine columns from two tables SIDE BY SIDE (wider result).
-- Set operations combine ROWS from two separate SELECT queries STACKED
-- on top of each other (taller result) -- like combining two lists.
--
-- RULES for all of these:
--   1. Both SELECT queries must return the SAME NUMBER of columns
--   2. The columns must be COMPATIBLE data types (e.g., both text, or both numbers)
--   3. Column NAMES in the final result come from the FIRST query
--
-- Note: INTERSECT and EXCEPT need MySQL 8.0.31+. If you're on an older
-- version, use the JOIN/subquery workarounds shown below each section.
-- ================================================================


-- 1. UNION -- combine rows from two queries, REMOVING duplicates
-- Example: a combined "contact list" of student names and department HODs
SELECT name AS person_name, 'student' AS role FROM students
UNION
SELECT hod_name AS person_name, 'hod' AS role FROM departments;
-- If a student happened to have the exact same name+role as a HOD row,
-- UNION would only show it ONCE (duplicates removed, like DISTINCT).


-- 2. UNION ALL -- combine rows from two queries, KEEPING duplicates
-- Faster than UNION because it skips the "check for duplicates" step.
SELECT name AS person_name, 'student' AS role FROM students
UNION ALL
SELECT hod_name AS person_name, 'hod' AS role FROM departments;

-- Rule of thumb: if you KNOW there won't be duplicates, or you don't care
-- about them, always prefer UNION ALL -- it's cheaper to run.


-- 3. INTERSECT -- rows that appear in BOTH queries' results
-- Example: student names that are ALSO used as an hod_name somewhere (unlikely
-- in your data, but shows the mechanic)
SELECT name FROM students
INTERSECT
SELECT hod_name FROM departments;


-- 4. EXCEPT -- rows in the FIRST query's results that do NOT appear in the second
-- (called MINUS in Oracle). Example: department names that have never been
-- used as anyone's course_name (contrived, but shows the pattern)
SELECT dept_name FROM departments
EXCEPT
SELECT course_name FROM courses;

-- More realistic EXCEPT use case: departments that have NO students
-- (you already know this pattern from the JOIN/subquery lessons -- EXCEPT
-- gives you a 3rd way to express the same thing)
SELECT dept_id FROM departments
EXCEPT
SELECT dept_id FROM students WHERE dept_id IS NOT NULL;


-- ================================================================
-- QUICK-FIRE DISTINCTIONS (common interview questions)
-- ================================================================
-- UNION vs UNION ALL:
--    UNION removes duplicate rows (does extra sorting/comparison work -> slower).
--    UNION ALL keeps every row including duplicates (faster, no dedup step).
--
-- UNION vs JOIN:
--    JOIN combines COLUMNS from two tables into wider rows (side by side).
--    UNION combines ROWS from two queries into a taller single list (stacked).
--
-- INTERSECT vs INNER JOIN:
--    Similar idea (only matching data), but INTERSECT compares entire ROWS
--    between two independent queries; INNER JOIN matches on a specific
--    column condition and can pull in extra columns from both sides.


-- ================================================================
-- NULL HANDLING -- EXPLAINED FROM SCRATCH
-- ================================================================
-- WHAT IS NULL?
-- NULL means "unknown / missing value" -- it is NOT the same as 0, an
-- empty string '', or false. It literally means "we don't know this value".
-- Example in your schema: a student's dept_id becomes NULL if their
-- department is deleted (ON DELETE SET NULL) -- it doesn't mean "department 0",
-- it means "this student currently has no known department".
--
-- THE #1 GOTCHA: NULL breaks normal comparison logic.
--   column = NULL   -> is NEVER true, even if column IS actually NULL
--   column != NULL  -> is NEVER true either
-- This is because SQL uses THREE-VALUED LOGIC: TRUE, FALSE, and UNKNOWN.
-- Comparing anything to NULL gives UNKNOWN, not TRUE or FALSE -- and WHERE
-- only keeps rows where the condition is TRUE (UNKNOWN rows get excluded).
-- ================================================================


-- 1. WRONG way to check for NULL (this returns ZERO rows, even if NULLs exist!)
SELECT * FROM students WHERE dept_id = NULL;     -- always empty, this is a common bug

-- 2. CORRECT way to check for NULL -- use IS NULL / IS NOT NULL
SELECT * FROM students WHERE dept_id IS NULL;
SELECT * FROM students WHERE dept_id IS NOT NULL;


-- 3. COALESCE -- returns the first NON-NULL value from a list
-- Useful for "show a fallback value if this column is NULL"
SELECT name, COALESCE(dept_id, -1) AS dept_id_or_default
FROM students;
-- Reads as: "give me dept_id, but if it's NULL, show -1 instead"

-- Practical example: show department name, or 'Unassigned' if the student
-- has no department
SELECT s.name, COALESCE(d.dept_name, 'Unassigned') AS dept_name
FROM students s
LEFT JOIN departments d ON s.dept_id = d.dept_id;


-- 4. IFNULL -- MySQL shorthand for COALESCE with exactly 2 values
-- (COALESCE can take many values; IFNULL only takes exactly 2 -- functionally
-- identical when you only need one fallback)
SELECT name, IFNULL(dept_id, -1) AS dept_id_or_default
FROM students;


-- 5. NULLIF -- returns NULL if two values are EQUAL, otherwise returns the first value
-- Useful for avoiding division-by-zero: if a value might be 0, turn it into
-- NULL first so division returns NULL instead of erroring
SELECT name, gpa / NULLIF(0, 0) AS safe_division_example FROM students;
-- (contrived example since gpa never divides by a real column here, but this
-- is THE classic use case: SUM(x) / NULLIF(COUNT(x), 0) to avoid divide-by-zero)


-- 6. Aggregate functions IGNORE NULLs automatically
-- AVG/SUM/MAX/MIN/COUNT(column) all skip NULL values -- they don't treat NULL as 0
SELECT AVG(gpa) FROM students;   -- if any gpa were NULL, it would be excluded
                                  -- from both the sum AND the count used for the average

-- COUNT(*) vs COUNT(column) -- the classic NULL-related interview question:
SELECT COUNT(*) AS all_rows, COUNT(dept_id) AS non_null_dept_rows FROM students;
-- COUNT(*) counts every row regardless of NULLs.
-- COUNT(dept_id) only counts rows where dept_id IS NOT NULL.


-- 7. NULL in NOT IN -- the dangerous gotcha you already saw in subqueries
-- If the subquery returns even ONE NULL, the entire NOT IN returns ZERO rows
-- (because "x <> NULL" is UNKNOWN, not TRUE, for every comparison)
SELECT name FROM students
WHERE student_id NOT IN (SELECT student_id FROM enrollments);
-- If enrollments.student_id ever contains a NULL, this returns NOTHING,
-- even for students who are obviously not enrolled. Always prefer NOT EXISTS
-- for this reason (shown below):
SELECT s.name FROM students s
WHERE NOT EXISTS (SELECT 1 FROM enrollments e WHERE e.student_id = s.student_id);


-- 8. ORDER BY and NULL -- where do NULLs sort?
-- MySQL treats NULL as the "smallest" value by default:
SELECT name, dept_id FROM students ORDER BY dept_id ASC;   -- NULLs appear FIRST
SELECT name, dept_id FROM students ORDER BY dept_id DESC;  -- NULLs appear LAST

-- Force NULLs to the end regardless of ASC/DESC (common reporting need):
SELECT name, dept_id FROM students
ORDER BY (dept_id IS NULL), dept_id ASC;
-- (dept_id IS NULL) evaluates to 0 for non-NULL rows and 1 for NULL rows,
-- so sorting by that first pushes all NULLs to the bottom.


-- ================================================================
-- QUICK-FIRE DISTINCTIONS (common interview questions)
-- ================================================================
-- Why doesn't "column = NULL" work?
--    Because NULL means "unknown" -- you can't say something EQUALS an
--    unknown value. SQL uses three-valued logic (TRUE/FALSE/UNKNOWN), and
--    any comparison involving NULL evaluates to UNKNOWN, which WHERE treats
--    as "exclude this row".
--
-- COALESCE vs IFNULL:
--    IFNULL takes exactly 2 arguments (MySQL-specific).
--    COALESCE takes 2+ arguments and returns the first non-NULL one
--    (works across MySQL/Postgres/SQL Server -- more portable).
--
-- Does NULL = NULL return TRUE?
--    No -- it returns NULL/UNKNOWN, not TRUE. Only IS NULL correctly detects NULL.


-- ================================================================
-- NORMALIZATION (1NF -> 2NF -> 3NF -> BCNF) -- EXPLAINED FROM SCRATCH
-- ================================================================
-- WHAT IS NORMALIZATION?
-- It's a set of rules for organizing tables so that data isn't repeated
-- unnecessarily, and so that updating one fact doesn't require updating
-- it in many places (which risks the data becoming inconsistent).
--
-- Each "Normal Form" (NF) is a stricter rule than the one before it.
-- You typically design tables to satisfy 3NF; BCNF is an even stricter
-- edge-case version of 3NF.
--
-- This file uses your OWN college_db schema as the running example,
-- plus a deliberately BAD "un-normalized" example to show what
-- normalization actually fixes.
-- ================================================================


-- ================================================================
-- THE BAD EXAMPLE (imagine if you had done this instead):
-- ================================================================
-- CREATE TABLE bad_enrollments (
--     student_id INT,
--     student_name VARCHAR(100),
--     student_email VARCHAR(150),
--     course1_name VARCHAR(100),
--     course1_grade CHAR(2),
--     course2_name VARCHAR(100),
--     course2_grade CHAR(2),
--     dept_name VARCHAR(100),
--     hod_name VARCHAR(100)
-- );
-- Problems with this design:
--   - "course1", "course2" columns -> what if a student takes a 3rd course?
--     You'd need to keep adding more columns forever. This violates 1NF.
--   - student_name/student_email repeated on every row for every course
--     they take -> if the student's email changes, you must update it in
--     MULTIPLE rows, and it's easy to miss one (data becomes inconsistent).
--   - dept_name/hod_name repeated for every student in that department ->
--     if the HOD changes, you must update EVERY student row in that dept.
-- Your actual schema (students, departments, courses, enrollments as
-- SEPARATE tables linked by foreign keys) already avoids all of this --
-- it's already normalized. This file explains WHY that design is correct.
-- ================================================================


-- 1. FIRST NORMAL FORM (1NF)
-- Rule: every column must hold a single (atomic) value -- no lists, no
-- repeating groups of columns (like course1, course2, course3 above),
-- and every row must be uniquely identifiable.
--
-- Your enrollments table follows 1NF correctly: instead of cramming
-- multiple courses into one row's columns, EACH course a student takes
-- gets its OWN separate row:
SELECT * FROM enrollments;
-- One student_id can appear in MANY rows (once per course) -- that's the
-- correct 1NF way to represent "a student can take many courses",
-- instead of adding course1/course2/course3 columns.


-- 2. SECOND NORMAL FORM (2NF)
-- Rule: 1NF, PLUS -- every non-key column must depend on the ENTIRE
-- primary key, not just PART of it. This only matters for tables with a
-- COMPOSITE primary key (made of 2+ columns).
--
-- Your enrollments table's primary key is (student_id, course_id) --
-- a composite key. Let's check its other columns:
--   grade    -> depends on BOTH student_id AND course_id together
--               (this specific student's grade in this specific course) -- OK
--   semester -> depends on BOTH student_id AND course_id together
--               (which semester THIS student took THIS course) -- OK
-- If you had instead added a "course_name" column directly into
-- enrollments, THAT would violate 2NF -- course_name only depends on
-- course_id (part of the key), not on student_id too. This is exactly
-- why course_name lives in the separate "courses" table instead.


-- 3. THIRD NORMAL FORM (3NF)
-- Rule: 2NF, PLUS -- no "transitive dependency" -- a non-key column
-- can't depend on ANOTHER non-key column. Every non-key column must
-- depend ONLY on the primary key directly.
--
-- Example of what would BREAK 3NF: if your students table had both
-- dept_id AND dept_name as columns:
--   dept_name doesn't depend on student_id (the primary key) --
--   it depends on dept_id, which is itself just another column.
--   That's a transitive dependency: student_id -> dept_id -> dept_name.
-- Your actual design avoids this: students only stores dept_id (a
-- foreign key reference), and dept_name lives ONLY in the departments
-- table, looked up via JOIN when needed:
SELECT s.name, s.dept_id, d.dept_name
FROM students s
JOIN departments d ON s.dept_id = d.dept_id;
-- This is exactly why we JOIN instead of duplicating dept_name onto
-- every student row -- if a department gets renamed, you update ONE row
-- in "departments", not every student in that department.


-- 4. BOYCE-CODD NORMAL FORM (BCNF)
-- Rule: an even stricter version of 3NF. Says: for every dependency
-- "A determines B" in the table, A must be a CANDIDATE KEY (something
-- that could uniquely identify a row on its own).
-- This mostly matters for tables with unusual OVERLAPPING candidate
-- keys, which your schema doesn't have -- if a table satisfies 3NF and
-- has a single, simple primary key (like all of yours do), it's already
-- in BCNF too. This is a rare edge case interviewers ask about mostly
-- to test if you know the DEFINITION, not to design around.


-- ================================================================
-- DENORMALIZATION -- the deliberate opposite, done on purpose
-- ================================================================
-- Sometimes for READ-heavy reporting/analytics, teams intentionally
-- duplicate data (like adding dept_name directly onto the students
-- table) to avoid JOINs and make reads faster -- trading some data
-- redundancy/update complexity for query speed. This is a conscious
-- design choice made AFTER normalizing, not a mistake -- e.g. a VIEW
-- (see sql_views.sql) is often a better way to get this benefit without
-- actually duplicating the underlying data.


-- ================================================================
-- QUICK-FIRE DISTINCTIONS (common interview questions)
-- ================================================================
-- 1NF vs 2NF vs 3NF -- one-line summary each:
--   1NF -> atomic values, no repeating column groups
--   2NF -> 1NF + no partial dependency on part of a composite key
--   3NF -> 2NF + no transitive dependency (non-key depending on non-key)
--
-- Why normalize at all?
--   Prevents update anomalies -- e.g. changing a department's HOD name
--   in ONE place instead of every student row referencing that dept.
--   Reduces storage redundancy and keeps data consistent.
--
-- When would you deliberately break normalization (denormalize)?
--   For read-heavy reporting/analytics workloads where JOIN performance
--   matters more than avoiding redundancy -- a common trade-off, not a mistake.