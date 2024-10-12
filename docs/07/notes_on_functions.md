# Notes on functions

<https://claude.ai/chat/089bdc9b-e848-40f7-9235-ee1b0f55b87b>

- diff between SQL functions and PL/pgSQl functions
  - <https://www.postgresql.org/docs/current/xfunc-sql.html>

- diff between procedures and functions (returns VOID)
-

## PL/pgSQL

PL/pgSQL  is a loadable procedural language : Procedural Language for Postgresql

can be used to create functions, procedures, and triggers,

Interest

Executing a query implies comm between the client (the app) and the PostgreSQL server.
By using functions, the processing happens on the server

    Extra round trips between client and server are eliminated

    Intermediate results that the client does not need do not have to be marshaled or transferred between server and client

    Multiple rounds of query parsing can be avoided

=> performance increase

## Functions

PL/pgSQL functions are useful for:

- Encapsulating complex logic
- Improving performance by reducing round-trips between the application and the database
- Implementing business rules directly in the database
- Creating reusable code blocks
- Performing batch operations on data

### Writing tests for functions

pgTAP is a popular unit testing framework for PostgreSQL.

<https://claude.ai/chat/c65fad8a-9bdd-4035-8eed-4bee3c21618f>

## Cursors

way to loop ovr a function

Cursors are particularly useful in scenarios such as:

Processing large datasets without loading everything into memory
Performing row-by-row operations that depend on the state of previous rows
Implementing pagination in applications
Creating dynamic reports
Batch processing of data

The main operations you can perform with cursors are:

OPEN: Executes the query and prepares the results for fetching
FETCH: Retrieves the next row from the cursor
CLOSE: Closes the cursor and releases resources

Cursor Attributes

PL/pgSQL provides several attributes for cursors:

FOUND: Boolean indicating if the last fetch operation retrieved a row
NOTFOUND: The logical inverse of FOUND
ROWCOUNT: The number of rows processed so far
ISOPEN: Boolean indicating if the cursor is currently open

#### Explicit

```sql
CREATE OR REPLACE FUNCTION process_employees(dept_id integer)
RETURNS TABLE (emp_id integer, emp_name text, new_salary numeric) AS $$
DECLARE
    emp_cursor CURSOR FOR
        SELECT id, name, salary
        FROM employees
        WHERE department_id = dept_id;
    emp_record RECORD;
BEGIN
    OPEN emp_cursor;

    LOOP
        FETCH emp_cursor INTO emp_record;
        EXIT WHEN NOT FOUND;

        -- Process each employee
        emp_id := emp_record.id;
        emp_name := emp_record.name;
        new_salary := emp_record.salary * 1.1;  -- 10% raise

        -- Update the employee's salary
        UPDATE employees SET salary = new_salary WHERE id = emp_id;

        RETURN NEXT;
    END LOOP;

    CLOSE emp_cursor;
END;
$$ LANGUAGE plpgsql;
```

#### Implicit : LOOP

```sql
CREATE OR REPLACE FUNCTION sum_employee_salaries(dept_id integer)
RETURNS numeric AS $$
DECLARE
    total_salary numeric := 0;
BEGIN
    FOR emp_record IN
        SELECT salary FROM employees WHERE department_id = dept_id
    LOOP
        total_salary := total_salary + emp_record.salary;
    END LOOP;

    RETURN total_salary;
END;
$$ LANGUAGE plpgsql;
```

## STABLE and IMMUTABLE functions differently from VOLATILE functions

## can you write test for your functions ?

## EXPLAiN functions

Black Box Nature: The query planner treats user-defined functions as black boxes, meaning it can't optimize what happens inside the function.

Performance Impact: Using functions in WHERE clauses can prevent the use of indexes, potentially impacting performance.

## Examples

```sql
CREATE [OR REPLACE] FUNCTION function_name(parameter1 type, parameter2 type, ...)
RETURNS return_type AS $$
DECLARE
    -- Variable declarations
BEGIN
    -- Function body
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```

simple example: adding

```sql
CREATE OR REPLACE FUNCTION add_numbers(a integer, b integer)
RETURNS integer AS $$
BEGIN
    RETURN a + b;
END;
$$ LANGUAGE plpgsql;
```

## With query

```sql
CREATE OR REPLACE FUNCTION update_employee_salary(emp_id integer, salary_increase numeric)
RETURNS void AS $$
BEGIN
    UPDATE employees
    SET salary = salary + salary_increase
    WHERE id = emp_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Employee with ID % not found', emp_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

## Ideas

- create a function, a trigger that calls an api
example : upate / insert lat long => calls the BAN API to get the real address
,

also materialized views <https://medium.com/@ShivIyer/optimizing-materialized-views-in-postgresql-best-practices-for-performance-and-efficiency-3e8169c00dc1>
