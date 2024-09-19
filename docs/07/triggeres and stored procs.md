----------------------------------
# Triggers and Stored procedures
----------------------------------
https://www.postgresql.org/docs/current/triggers.html

* Procedure Tutorial in SQL | SQL Stored Procedure | Procedure in SQL
https://www.youtube.com/watch?v=yLR1w4tZ36I&t=425s



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

