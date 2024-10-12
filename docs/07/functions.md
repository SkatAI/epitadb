# Functions

----------------------------------

<https://www.postgresql.org/docs/current/plpgsql.html>

1. Introduction
   - Learning objectives: What students will gain from this class
   - Brief overview of functions in PostgreSQL

### Overview of Functions in PostgreSQL

Functions in PostgreSQL are user-defined routines that encapsulate a sequence of operations and can be invoked by name. They are powerful tools that allow you to perform calculations, manipulate data, and execute complex logic within the database.

#### Key Characteristics

1. **Encapsulation of Logic**:
   - Functions allow you to encapsulate and reuse SQL queries and logic. This helps to maintain a DRY (Don't Repeat Yourself) codebase, as you can define the logic once in a function and call it multiple times.

2. **Return Types**:

   - **Scalar Functions**: Return a single value, such as an integer, text, date, etc.
   - **Table Functions**: Return a set of rows, behaving like a table in a query.
   - **Void Functions**: Perform actions without returning a value.

3. **Input Parameters**:
   - Functions can accept input parameters, which allow you to pass values into the function to customize its behavior or output. Parameters can be of any PostgreSQL data type.

4. **Languages Supported**:
   - PostgreSQL functions can be written in several languages, with the most common being SQL and PL/pgSQL (PostgreSQL's procedural language). Other supported languages include PL/Python, PL/Perl, PL/Tcl, and more.

5. **Execution Context**:
   - Functions in PostgreSQL can be executed in the context of a SQL statement. They can be used in `SELECT` statements, `WHERE` clauses, `INSERT`, `UPDATE`, `DELETE` operations, and more.

6. **Volatility Categories**:
   - **Immutable**: The function always returns the same result given the same input, with no side effects (e.g., mathematical functions).
   - **Stable**: The function returns consistent results within a single query execution, but may return different results in different queries (e.g., functions that access the database).
   - **Volatile**: The function can return different results even within a single query execution (e.g., functions that read from system clocks).

7. **Error Handling**:
   - Functions in PL/pgSQL support error handling using `BEGIN...EXCEPTION...END` blocks, allowing you to handle exceptions and ensure graceful failure.

#### Basic Example

A simple function to add two numbers:

```sql
CREATE FUNCTION add_numbers(a INT, b INT) RETURNS INT AS $$
BEGIN
    RETURN a + b;
END;
$$ LANGUAGE plpgsql;
```

This function `add_numbers` takes two integers as input and returns their sum.

#### Usage

- **Calling a Function**:

  ```sql
  SELECT add_numbers(3, 5);  -- Returns 8
  ```

- **Using a Function in Queries**:

  ```sql
  SELECT customer_id, add_numbers(order_value, tax_amount) AS total_amount
  FROM orders;
  ```

#### Advanced Usage

- **Table-Returning Functions**: A function that returns a set of rows can be treated like a table in queries.

  ```sql
  CREATE FUNCTION get_active_customers() RETURNS TABLE(customer_id INT, name TEXT) AS $$
  BEGIN
      RETURN QUERY
      SELECT customer_id, name
      FROM customers
      WHERE status = 'active';
  END;
  $$ LANGUAGE plpgsql;
  ```

  Usage:

  ```sql
  SELECT * FROM get_active_customers();
  ```

- **Functions with Error Handling**:

  ```sql
  CREATE FUNCTION divide_numbers(a NUMERIC, b NUMERIC) RETURNS NUMERIC AS $$
  BEGIN
      IF b = 0 THEN
          RAISE EXCEPTION 'Division by zero';
      END IF;
      RETURN a / b;
  END;
  $$ LANGUAGE plpgsql;
  ```

  This function handles division by zero by raising an exception.

### Summary

Functions in PostgreSQL are versatile and powerful, enabling you to create reusable logic within the database. They support various return types, can accept input parameters, and can be written in different languages. Whether performing simple calculations or complex operations involving multiple SQL statements, functions are an essential tool for database development and management.

3. Creating and Managing Functions
   3.1. Basic Function Creation
       - Syntax for CREATE FUNCTION
       - Defining input parameters and return types

   3.2. Function Body
       - PL/pgSQL language basics
       - SQL functions vs. Procedural functions

   3.3. Modifying Functions
       - CREATE OR REPLACE FUNCTION

   3.4. Deleting Functions
       - DROP FUNCTION command

### Hands on

scalar functions: stats on tables (number of trips, average price, diameter from circumference, or volume, -> closest tree <-)
table valued functions: returns relations

in the context of a query:
select closes_tree() as neighbor_tree_id from ....
update statstable set ... = function(), ... where id = ...

4. Types of Functions
   4.1. Scalar Functions
       - Returning single values

   4.2. Table-Valued Functions
       - Returning result sets

   4.3. Aggregate Functions
       - Creating custom aggregates

5. Function Overloading
   5.1. Concept and Benefits
       - Multiple functions with the same name, different parameters

   5.2. Implementation
       - Creating overloaded functions
       - How PostgreSQL chooses the appropriate function

   5.3. Best Practices
       - When to use function overloading
       - Potential pitfalls and how to avoid them

6. Advanced Concepts
   6.1. Transaction Control
       - Managing transactions in functions

   6.2. Exception Handling
       - RAISE statement
       - Custom exception handling

   6.3. Security and Permissions
       - SECURITY DEFINER vs. SECURITY INVOKER

7. Hands-on Workshop
   - Setting up a PostgreSQL environment
   - Creating a sample database
   - Exercises:
     a. Creating a simple scalar function
     b. Developing a table-valued function
     c. Implementing an aggregate function
     d. Creating and using overloaded functions
     e. Working with transactions in functions
     f. Handling exceptions in functions

8. Best Practices and Optimization
   - Naming conventions
   - Performance considerations
   - When to use different types of functions

9. Conclusion
   - Recap of key concepts
   - Preview of upcoming stored procedures class
   - Additional resources for further learning

Class 2: PostgreSQL Stored Procedures (Outline)

1. Introduction to Stored Procedures
2. Differences between Functions and Procedures
3. Creating and Managing Stored Procedures
4. Calling and Using Stored Procedures
5. Advanced Topics in Stored Procedures
6. Hands-on Workshop
7. Best Practices
8. Conclusion

This structure allows for a more in-depth focus on functions in the first class, including the new section on function overloading. The second class can then dive into the specifics of stored procedures, building on the knowledge gained from the functions class.

Would you like me to elaborate on any specific section or provide more details for the workshop exercises?
