# Intro - launch
----------------


- Understand context, tools and setup
- Course logistics and curriculum
- initial assessment : quizz
- Sources: postgres doc, books, sites [todo add art of postgres]
- Relational vs other types of dbs : vectors, nosql, json
- postgres vs other dbs
- installs postgres and psql on local
- psql : create db, load data
- execution time``
- .psqlrc
- pgAdmin
- creates db and loads dataset from csv
- CTEs


# Normalization
----------------
- OLTP vs OLAP
- generate Entity-Relationship Diagrams ERDs
- design a database schema
- normalization vs denormalization
- speed vs maintenance![](data:image/- identify anomalies
- normal forms 1NF, 2NF, 3NF (guidelines)
- [missing] functional dependency


## workshop:
- modifies trees db by creating new tables from original table so that db is normalized
- apply normal forms to design database
- creates new tables with redundancy to speed up queries
- updates redundant data in denormalized schema

- denormalize ademe

## todo
- clean up and publish workshop on normalizing treesdb
- norm / denorm : assess understanding with questions
- write an update and a select query on a normalized and denormalized version of a db

----------------------------------
# Optimization 1
----------------------------------

Goals :
- optimize a query
- read an execution plan
- apply and use index

### background & theory
SQL : declarative language not an imperative language [p27]
theory : filter, project, product

from query to exec : compilation, optimization, execution
what is a relation

- cost function & algorithm
- indexes
- short vs long queries
- Execution plans
- query optimizer
- scans
- table partitioning

setup or connect to postgres_air database
Illustrate each item with an exercise on optimizing a given query
see query optimization
from high level questions, write queries and optimize the queries
analyze multiple execution plans

### Todo
- have students run simple queries on the airdb database and explain them
	- show that plan is different from machine to machine
	- add indexes and show difference in explain

- show different types of operations
- explain meaning of info returrned by explain

### workshop
work on smaller version of ademe ? on local
run queries that are complex
explain queries
add index
check index is used
example where index is not used


# Optimization 2 + indexes
----------------------------------
data updates
too many indexes ?

go further iunto indexes
indexes for denormalized data types
impact of data type on query planning

also windows functions
https://www.youtube.com/watch?v=Ww71knvhQ-s&list=PLavw5C92dz9GbmgiW4TWVnxhjMFOIf0Q7

# Views
----------------------------------

1. Introduction
   - Learning objectives: What students will gain from this class
   - Brief overview of views in PostgreSQL

A **view** in PostgreSQL is a virtual table that is created by a `SELECT` query.
It acts as a stored query that users can treat like a regular table, allowing for the abstraction and simplification of complex queries.

Views are useful for OLAP databases

2. Why Views are Useful:
   - Simplifying complex queries
   - Data security and access control (limit displayed columns )
   - Consistency in data representation
   - Abstraction of underlying table structures (a strategy when the database is highly normalized and queries have many joins)

	2.1 **Virtual Table**:
   - A view does not store data itself. Instead, it presents data from one or more tables based on the query used to define it.
   - When you query a view, PostgreSQL executes the underlying `SELECT` statement and returns the result set as if it were a table.

	2.2. **Simplicity**:
   - Views simplify complex queries by encapsulating them into a single, reusable entity.
   - Users can select from a view without needing to know the underlying table structure or join conditions.

	2.3. **Security**:
   - Views can restrict access to specific data. For instance, you can create a view that only exposes certain columns of a table, thereby limiting what data users can see.

	2.4. **Data Abstraction**:
   - Views provide a layer of abstraction over the physical schema. This can be useful if the underlying schema changes, as you can update the view without affecting user queries.

	2.5. **Maintenance**:
	need to update the view when chaging the underlying tables
   - Views can be updated or dropped without affecting the underlying tables. However, changing the structure of underlying tables might require updating the associated views.

	2.6. **Performance Considerations**:
   - Since views are not stored with the data but are generated on the fly, complex views with multiple joins or subqueries can lead to performance issues, especially with large datasets.
   - => explain views!

	2.7. **Materialized Views**:
   - PostgreSQL also supports **materialized views**, which store the result of the `SELECT` query physically on disk.
   - This can improve performance for complex queries but requires manual or scheduled refreshing to keep the data up to date.
   - see https://www.postgresql.org/docs/current/rules-materializedviews.html
   - A materialized view is a tool that allows queries that would otherwise take too long to complete quickly, at the price of working with slightly stale data. You use it if you cannot find a better solution.

from https://www.postgresqltutorial.com/postgresql-views/postgresql-materialized-views/
To load data into a materialized view, you use the  REFRESH MATERIALIZED VIEW statement:

REFRESH MATERIALIZED VIEW view_name;
Code language: SQL (Structured Query Language) (sql)

When you refresh data for a materialized view, PostgreSQL locks the underlying tables. Consequently, you will not be able to retrieve data from underlying tables while data is loading into the view.

To avoid this, you can use the CONCURRENTLY option.

REFRESH MATERIALIZED VIEW CONCURRENTLY view_name;
Code language: SQL (Structured Query Language) (sql)

With the CONCURRENTLY option, PostgreSQL creates a temporary updated version of the materialized view, compares two versions, and performs INSERT and UPDATE only the differences.

To make the process automatic, we can create a schedule or set the database triggers to execute the REFRESH command. For instance, you can create a trigger that launches the updating process when any changes take place in the tables that feed the materialized view. It synchronizes the data for all the users working with the tables.

### Pros and Cons of Materialized Views in PostgreSQL

Materialized views are a powerful feature in PostgreSQL, providing a way to store the results of a query physically on disk, which can significantly improve performance for certain types of queries. However, they also come with trade-offs. Here's an overview of the pros and cons:

### Pros of Materialized Views

1. **Performance Improvement**:
   - **Faster Query Execution**: Since the data is precomputed and stored, queries that use materialized views are often much faster, especially for complex queries involving large datasets, joins, or aggregations.
   - **Reduced Computation Time**: Materialized views can offload expensive computations that would otherwise be performed each time a query is executed, reducing the overall load on the database.

2. **Data Aggregation and Summarization**:
   - **Pre-Aggregated Data**: They are ideal for scenarios where you need to frequently access aggregated or summarized data. By materializing the aggregation, you avoid the need to recompute it every time.

3. **Offloading Complex Queries**:
   - **Complex Calculations**: Materialized views can handle complex calculations, joins, or subqueries, storing the results so that they don't need to be recalculated every time a query is run.

4. **Data Snapshot**:
   - **Stable Data Set**: Since materialized views store the data physically, they can be used as a snapshot of the data at a particular point in time, which can be useful for historical analysis or reporting.

5. **Ease of Use**:
   - **Simplified Query Logic**: By encapsulating complex queries within a materialized view, you can simplify your query logic in the application layer, making the system easier to maintain and understand.

### Cons of Materialized Views

1. **Staleness of Data**:
   - **Data Might Be Outdated**: The data in a materialized view is only as fresh as the last time it was refreshed. If the underlying data changes frequently, the materialized view might become outdated, leading to stale data unless it is refreshed regularly.

2. **Maintenance Overhead**:
   - **Refresh Overhead**: Materialized views require explicit refreshing to update the stored data, which can be time-consuming and resource-intensive, especially if the view involves complex queries or large datasets.
   - **Manual or Scheduled Refresh**: Unlike regular views that always reflect the latest data, materialized views need to be refreshed manually or on a schedule, adding complexity to the database management process.

3. **Storage Space**:
   - **Additional Disk Usage**: Because materialized views store the data physically, they consume additional storage space in the database. This can be a concern if you are working with large datasets or have multiple materialized views.

4. **Complexity in Data Consistency**:
   - **Consistency Management**: Keeping the materialized view data consistent with the underlying tables can be complex, especially in environments where the base data changes frequently. Ensuring that the materialized view is refreshed at the right time to maintain data accuracy can be challenging.

5. **Write Performance Impact**:
   - **Impact on Insert/Update/Delete Operations**: If your database design relies heavily on materialized views, you might experience a performance hit during insert, update, or delete operations on the base tables, particularly if you choose to refresh materialized views immediately after these operations.

6. **Complexity in Implementation**:
   - **Trigger-Based Logic**: Implementing refresh strategies (e.g., using triggers or scheduled jobs) can add complexity to the database design and maintenance.

### Summary:
**Materialized views** are excellent for improving the performance of complex queries and providing precomputed, snapshot-like data. However, they require careful management to ensure data is up-to-date, and they involve trade-offs in terms of storage and refresh overhead. They are particularly useful in scenarios where data doesn't change frequently or where the cost of occasional refreshes is outweighed by the performance benefits.

### Creating a Materialized View in PostgreSQL

To create a materialized view in PostgreSQL, you use the `CREATE MATERIALIZED VIEW` statement, which is similar to creating a regular view but with the `MATERIALIZED` keyword.

#### Syntax to Create a Materialized View:
```sql
CREATE MATERIALIZED VIEW view_name AS
SELECT columns
FROM table_name
WHERE conditions;
```

### Example:
Suppose you have a table named `orders`, and you want to create a materialized view that aggregates the total sales per customer.

```sql
CREATE MATERIALIZED VIEW customer_sales_summary AS
SELECT customer_id, SUM(total_amount) AS total_sales
FROM orders
GROUP BY customer_id;
```
This command creates a materialized view named `customer_sales_summary` that stores the total sales per customer, aggregated from the `orders` table.

### Refreshing a Materialized View:
Since materialized views store data physically, they need to be refreshed to stay up-to-date with the underlying table data.

- **Manual Refresh**:
  ```sql
  REFRESH MATERIALIZED VIEW view_name;
  ```

  Example:
  ```sql
  REFRESH MATERIALIZED VIEW customer_sales_summary;
  ```

- **Automatic or Scheduled Refresh**:
  To automate the refresh process, you can use PostgreSQL's `pg_cron` extension or a scheduled job in your environment to call the `REFRESH MATERIALIZED VIEW` command at regular intervals.

### Changing a Regular View to a Materialized View

You cannot directly "convert" a regular view to a materialized view. Instead, you would need to drop the existing view and create a new materialized view with the same name (or a different one if you prefer).

#### Steps to Convert a View to a Materialized View:

1. **Drop the Existing View** (if necessary):
   ```sql
   DROP VIEW IF EXISTS view_name;
   ```
   Example:
   ```sql
   DROP VIEW IF EXISTS customer_sales_summary;
   ```

2. **Create a Materialized View**:
   ```sql
   CREATE MATERIALIZED VIEW view_name AS
   SELECT columns
   FROM table_name
   WHERE conditions;
   ```
   Example:
   ```sql
   CREATE MATERIALIZED VIEW customer_sales_summary AS
   SELECT customer_id, SUM(total_amount) AS total_sales
   FROM orders
   GROUP BY customer_id;
   ```

### Summary:
- To create a materialized view, use the `CREATE MATERIALIZED VIEW` statement.
- If you need to change an existing view to a materialized view, you have to drop the original view and create a new materialized view with the same query.
- Remember to refresh the materialized view to ensure it reflects the most up-to-date data.



	---------------------------
	/2.7. Materialized Views:
	------------------

--- activity
create a view on

3. Creating and Managing Views
   3.1. Basic View Creation
       - Syntax for CREATE VIEW
       - Selecting data from multiple tables

```sql
CREATE VIEW active_customers AS
SELECT customer_id, name, email
FROM customers
WHERE status = 'active';
```

In this example, `active_customers` is a view that shows only the active customers from the `customers` table. Users can query `active_customers` just like a table.

#### Usage:

- **Querying a View**:
  ```sql
  SELECT * FROM active_customers;
  ```
- **Updating a View** (if updatable):
  ```sql
  UPDATE active_customers SET status = 'inactive' WHERE customer_id = 1;
  ```

   3.5. **updatable Views**:

    Updatable views allow INSERT, UPDATE, and DELETE operations directly on the view, which are then propagated to the underlying base tables.

Characteristics:

    Simple Views: If a view is based on a single table and doesn't involve complex expressions, aggregates, or joins, PostgreSQL can generally map updates back to the base table, making the view updatable.
    Direct Modification: Users can modify the data in the view, and PostgreSQL will automatically apply those modifications to the underlying table(s).
    Rule System: PostgreSQL uses rules to determine how updates to the view translate to the base table(s). You can also define custom rules using the CREATE RULE command to make more complex views updatable.

Example of an Updatable View:

sql

CREATE VIEW active_customers AS
SELECT customer_id, name, email
FROM customers
WHERE status = 'active';

    This view selects data from a single table (customers). If customers is a straightforward table, this view is updatable. You can run an UPDATE on active_customers, and it will modify the customers table.

3. How to Make a View Updatable

    Single Table Requirement: The view should typically be based on a single table.
    No Aggregates or Grouping: Avoid using aggregate functions (SUM, COUNT, etc.), GROUP BY, DISTINCT, or similar operations that would make it unclear how to apply updates.
    Column Mapping: Each column in the view should directly correspond to a column in the base table.
    With CHECK OPTION: To ensure that any updates made through the view still satisfy the view's conditions, you can add WITH CHECK OPTION when creating the view.

	/3.5. updatable Views

3. Materialized views



4. Hands-on Workshop

working on the airdb database,
- simple view
make a simple view, ... with a couple of joins on the base tables

- complex view
get some specific info, query is complex, CTE ...
write the query (long)

create indexes as needed
create the query equivalent view
update the data in the view ... make the view updatable if necessarry

- update underlying table : add a new trip for a given user for instance
check that the view is also updated

- restrict elements returned by the view

- materialized view
make that view materialized
comparer execution times between the different views
refesh the materialized view


5. Best Practices and Advanced Topics
   - Naming conventions
   - Performance optimization
   - Using views for data analysis


# Functions
----------------------------------

https://www.postgresql.org/docs/current/plpgsql.html

1. Introduction
   - Learning objectives: What students will gain from this class
   - Brief overview of functions in PostgreSQL

### Overview of Functions in PostgreSQL

Functions in PostgreSQL are user-defined routines that encapsulate a sequence of operations and can be invoked by name. They are powerful tools that allow you to perform calculations, manipulate data, and execute complex logic within the database.

#### Key Characteristics:

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

#### Basic Example:

A simple function to add two numbers:

```sql
CREATE FUNCTION add_numbers(a INT, b INT) RETURNS INT AS $$
BEGIN
    RETURN a + b;
END;
$$ LANGUAGE plpgsql;
```

This function `add_numbers` takes two integers as input and returns their sum.

#### Usage:

- **Calling a Function**:
  ```sql
  SELECT add_numbers(3, 5);  -- Returns 8
  ```

- **Using a Function in Queries**:
  ```sql
  SELECT customer_id, add_numbers(order_value, tax_amount) AS total_amount
  FROM orders;
  ```

#### Advanced Usage:

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

### Summary:

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


----------------------------------
# Triggers and Stored procedures
----------------------------------
https://www.postgresql.org/docs/current/triggers.html


1. Introduction
   - Learning objectives
   - Brief recap of triggers and stored procedures

2. Triggers
   2.1. What are Triggers?
       - Definition and purpose
       - Types of triggers (BEFORE, AFTER, INSTEAD OF)
       - Event types (INSERT, UPDATE, DELETE, TRUNCATE)

Triggers in PostgreSQL:
1. Triggers are database objects that automatically execute a function in response to certain events on a specified table or view.
2. Trigger functions are typically written as regular PostgreSQL functions, but they have a special return type and follow specific conventions.
3. Triggers use functions, not stored procedures, in PostgreSQL.



   2.2. Creating Trigger Functions
       - Syntax for trigger functions
       - Special return type (trigger)
       - Accessing OLD and NEW row data

   2.3. Creating Triggers
       - Syntax for CREATE TRIGGER
       - Associating triggers with tables

   2.4. Managing Triggers
       - Enabling/disabling triggers
       - Dropping triggers

   2.5. Use Cases and Best Practices
       - When to use triggers
       - Performance considerations
       - Potential pitfalls

# 3. Stored Procedures
## 3.1. Introduction to Stored Procedures
## 3.2. Differences between Functions and Procedures


In PostgreSQL, both stored procedures and functions allow you to encapsulate SQL logic and reuse it, but there are key differences between the two.
Here’s a breakdown of the differences:

1. **Return Value:**
   - **Functions:** Must return a value. They can return a scalar value, a table, or a composite type. The return type is specified when the function is created.
   - **Procedures:** Do not return a value directly. They are primarily used for performing actions such as modifying data or interacting with other objects within the database.

2. **Execution:**
   - **Functions:** Can be called from within SQL statements, such as `SELECT`, `INSERT`, `UPDATE`, or `DELETE`. They can be used as part of a query.
   - **Procedures:** Cannot be called directly within SQL statements. They are executed using the `CALL` command.

3. **Transaction Control:**
   - **Functions:** Cannot manage transactions directly. They execute within the context of a single transaction, and any errors cause a rollback of the entire transaction.
   - **Procedures:** Can manage transactions directly using commands like `BEGIN`, `COMMIT`, and `ROLLBACK`. This allows more fine-grained control over transactions, making procedures more suitable for complex business logic.

4. **Side Effects:**
   - **Functions:** Generally, functions are expected to be deterministic (i.e., they should not have side effects and should produce the same result given the same input). However, in PostgreSQL, you can write functions with side effects, but this is not the typical use case.
   - **Procedures:** Are designed to perform actions that have side effects, such as modifying tables or performing administrative tasks.

5. **Syntax:**

   - **Function Creation Example:**
     ```sql
     CREATE FUNCTION add_numbers(a INT, b INT) RETURNS INT AS $$
     BEGIN
         RETURN a + b;
     END;
     $$ LANGUAGE plpgsql;
     ```
     This function adds two integers and returns the result.

   - **Procedure Creation Example:**
     ```sql
     CREATE PROCEDURE process_order(order_id INT) LANGUAGE plpgsql AS $$
     BEGIN
         -- Example: update order status and commit
         UPDATE orders SET status = 'processed' WHERE id = order_id;
         COMMIT;
     END;
     $$;
     ```
     This procedure updates an order's status and commits the transaction.

6. **Use Cases:**
   - **Functions:** Best used when you need to perform calculations, transform data, or return a result set based on input parameters.
   - **Procedures:** Best used when you need to perform a series of operations that might include transaction management, complex control-of-flow logic, or when performing administrative tasks.

7. **Overloading:**
   - **Functions:** Can be overloaded, meaning you can have multiple functions with the same name but different argument types.
   - **Procedures:** Also support overloading in PostgreSQL.

In summary, functions are generally used for computations and returning data, while procedures are used for performing actions, especially those involving transaction control or complex business logic.

   3.3. Creating and Managing Stored Procedures
   3.4. Calling and Using Stored Procedures
   3.5. Advanced Topics in Stored Procedures

4. Hands-on Workshop
   - Setting up a PostgreSQL environment
   - Creating a sample database
   - Exercises:
     a. Creating a trigger function for auditing
     b. Implementing BEFORE and AFTER triggers
     c. Using triggers for data validation
     d. Creating and calling a simple stored procedure
     e. Comparing function, trigger, and procedure usage

5. Best Practices and Optimization
   - When to use functions vs. triggers vs. procedures
   - Performance considerations
   - Naming conventions and code organization

6. Conclusion
   - Recap of key concepts
   - Additional resources for further learning


----------------------------------
# Transactions and Concurrency Control
----------------------------------


----------------------------------
# Database Security
# + Roles
----------------------------------


https://www.postgresql.org/docs/current/client-authentication.html
----------------------------------
# Maintenance and Monitoring
----------------------------------

https://www.postgresql.org/docs/current/admin.html


----------------------------------
# cloud
----------------------------------
big query ? setup on VM ? ...





----------------------------------
# Other
----------------------------------
schemas and search path ?
pg_hba and postgres.conf
window functions


ACID properties: https://www.geeksforgeeks.org/acid-properties-in-dbms/


----------------------------------
# Project / Exam
----------------------------------

see this example on a Kaggle dataset
Complete guide to Database Normalization in SQL
https://www.youtube.com/watch?v=rBPQ5fg_kiY

Practice Writing SQL Queries using Real Dataset(Practice Complex SQL Queries)
Olympic dataset
https://www.youtube.com/watch?v=XruOBp7yPXU




----------------------------------
# Resources
----------------------------------
* Procedure Tutorial in SQL | SQL Stored Procedure | Procedure in SQL
https://www.youtube.com/watch?v=yLR1w4tZ36I&t=425s

* window function in SQL
https://www.youtube.com/watch?v=Ww71knvhQ-s&

longer version:
https://www.youtube.com/watch?v=zAmJPdZu8Rg&

* CTEs
 SQL WITH Clause | How to write SQL Queries using WITH Clause | SQL CTE (Common Table Expression)
https://www.youtube.com/watch?v=QNfnuK-1YYY