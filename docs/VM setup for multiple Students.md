# Student VM setup

to allow each student to access the main database and create their own objects: tables, indexes, views etc ...



Certainly! I'll walk you through setting up individual schemas for each student and implementing role-based access control in PostgreSQL on your GCP VM running Debian. This approach will allow each student to have their own workspace while maintaining security and isolation.

Let's go through this step-by-step:

1. Connect to your GCP VM and ensure PostgreSQL is installed and running.

2. Connect to PostgreSQL as the superuser (usually 'postgres'):

   ```
   sudo -u postgres psql
   ```

3. Create a new database for your course (if you haven't already):

   ```sql
   CREATE DATABASE course_db;
   \c course_db
   ```

4. Now, let's create a function to set up a student's schema and role:

   ```sql
   CREATE OR REPLACE FUNCTION setup_student(username TEXT) RETURNS VOID AS $$
   BEGIN
     -- Create a new role for the student
     EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', username, username);
     
     -- Create a schema for the student
     EXECUTE format('CREATE SCHEMA %I AUTHORIZATION %I', username, username);
     
     -- Grant usage on public schema
     EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', username);
     
     -- Set default privileges for the student in their schema
     EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I 
                     GRANT ALL ON TABLES TO %I', username, username, username);
     EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I 
                     GRANT ALL ON SEQUENCES TO %I', username, username, username);
     EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I 
                     GRANT ALL ON FUNCTIONS TO %I', username, username, username);
     
     -- Set search_path for the student
     EXECUTE format('ALTER ROLE %I SET search_path TO %I, public', username, username);
   END;
   $$ LANGUAGE plpgsql;
   ```

5. Now, let's create schemas and roles for each student. You can do this in a loop if you have a list of student usernames. For this example, let's create it for two students:

   ```sql
   SELECT setup_student('student1');
   SELECT setup_student('student2');
   ```

6. Grant necessary privileges on the public schema:

   ```sql
   GRANT USAGE ON SCHEMA public TO public;
   GRANT CREATE ON SCHEMA public TO public;
   ```

7. If you have specific tables in the public schema that all students should be able to read (like the airdb or ademedb tables), grant SELECT privileges:

   ```sql
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO public;
   ```

8. To ensure future tables in the public schema get the same permissions:

   ```sql
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO public;
   ```

9. Create a role for you (the instructor) with superuser privileges:

   ```sql
   CREATE ROLE instructor WITH SUPERUSER LOGIN PASSWORD 'your_secure_password';
   ```

Now, each student has their own schema and can create objects within it. They can also read from the public schema but can't modify it. Here's how a student would connect:

```
psql -h [VM_IP] -U student1 -d course_db
```

When they connect, their search_path will be set to their schema first, then public. This means if they create a table without specifying the schema, it will be created in their personal schema.

To test this setup:

1. Connect as a student:
   ```
   psql -h [VM_IP] -U student1 -d course_db
   ```

2. Try creating a table:
   ```sql
   CREATE TABLE test_table (id serial PRIMARY KEY, data text);
   ```

3. This table should be created in the student1 schema. Verify with:
   ```sql
   \dt student1.*
   ```

4. Try selecting from a public table (if you've set one up):
   ```sql
   SELECT * FROM public.some_table LIMIT 5;
   ```

5. Try creating a table in another student's schema (this should fail):
   ```sql
   CREATE TABLE student2.test_table (id serial PRIMARY KEY, data text);
   ```

This setup provides a good balance of isolation and shared resources. Each student can work independently in their own schema, but they can also access shared data in the public schema. As the instructor, you retain superuser access to manage the entire database.

Remember to provide each student with their username and password (initially set to their username in this example, but you should encourage them to change it). Also, make sure to set up appropriate firewall rules in GCP to allow incoming connections to PostgreSQL.