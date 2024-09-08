# Window function

scripts available in github ./sql/...

Day 3

What are Window functions and when to use them

This video is about Window Functions in SQL which is also referred to as Analytic Function in some of the RDBMS. SQL Window Functions covered in this video are RANK, DENSE RANK, ROW NUMBER, LEAD, LAG. Also, we see how to use SQL Aggregate functions like MIN, MAX, SUM, COUNT, AVG as window function. 

This video is focused on teaching how to write SQL Queries using different window functions or analytic functions. We go through the syntax of using rank, dense_rank, row_number, lead, lag and max functions as window function.

Over clause is explained in detail in this video. Over clause is used in SQL when we need to use window function. Inside Over clause, we also use Partition By clause and also Order by clause.
Partition By clause is used to specify the column based on which different windows needs to be created.

The window function you learn in this video is applicable to any RDBMS since these functions are commonly used across most of the popular RDBMS such as Oracle, MySQL, PostgreSQL, Microsoft SQL Server etc.

## Plan

00:00 Intro
01:33 Understanding Aggregate function
03:16 Syntax to write SQL Query using Window Function
06:33 ROW_NUMBER() Window Function in SQL
11:57 RANK() Window Function in SQL
15:43 DENSE_RANK() Window Function in SQL
17:10 Difference between RANK, DENSE RANK and ROW NUMBER in SQL
17:59 LEAD() and LAG() Window Function in SQL


## transcript
what kind of queries can you handle 

create employee table 
- id
- name
- dept
- salary

max salary for an employee
select max(salaty as max_salary) from employee;

max salary for an employee in each departmentt
group by dept_name 

extract max salary in each dept 
but keep the other details for each salary
we can do that with subqueries
but best way is to use window function

```sql
select e.*,
max(salary) over() as max_salary
from employee e;
```

it adds a max salary colinn

the OVEr() clause specifies to SQL that you need to create a _window of records_

without specifying a column in the OVER clause SQL creates one window function over all the records

so if we want the max salary for each dept 
we can add dept_name in the over clause using partition by

as such:

```sql
select e.*,
max(salary) over(partition by dept_name) as max_salary
from employee e;
```

it will create one window for all records in one dept name 
and calculate the max(salary) in each window

Then we get the max salary by dept and not the overall max salary

that words with max, mon, avg etc ...

### row_number()

will assign a unique value to all records in the table

```sql
select e.*,
row_number() over() as rn
from employee e
```

rn is the same as the id 

but if we want to restart the row number per dept 

```sql
select e.*,
row_number() over(partition as dept_name) as rn
from employee e
```

the rn is reset to  1 for each dept

when is that useful ?

for instance fetch the 2 first employees from each dept to join the company
assuming that the emp_id is a proxy for joining the company date

we can filter with rn <= 2

-- order by emp_id
```sql
select e.*,
row_number() over(partition as dept_name orrder by emp_id) as rn
from employee e
```

then subquery 
```sql
select * form (
    select e.*,
    row_number() over(partition as dept_name order by emp_id) as rn
    from employee e) X
where X.rn < 3;    

```


can we order and find the employee with the lowest / highest salary in each dept


can we combine column in partition as 
for instance partition as species and arrondissement


### rank

fetch the top 3 employees in each dept earning the max salary


should be doable with similar query 
```sql
select * form (
    select e.*,
    row_number() over(partition by dept_name order by emp_id) as rn
    from employee e) X
where X.rn < 3;    

```

but using rank()
```sql
select e.*,
rank() over(partition by dept_name order by salary desc) as rnk
from employee e;
```

equal values will have the same rank 
so rank can be 1, 2, 2, 4

so employees with top 3 salaries 

```sql
select * from (
select e.*,
rank() over(partition by dept_name order by salary desc) as rnk
from employee e) as X
where X.rnk < 4;
```
we get 3 employees for the Admin dept


### dense_rank()
similar to rank

```sql
select e.*,
rank() over(partition by dept_name order by salary desc) as rnk
dense_rank() over(partition by dept_name order by salary desc) as dense_rnk
from employee e;
```

will increment the rank without jumps


Compare the 3 function rn, rnk and dense_rnk

## lead and lag

query to display if the salary if an employee is higher lower or equal than the previous (as joined company date) employee

```sql
select e.*,
lag(salary) over(partition by dept_name order by emp_id) as prev_emp_salary
from employee e;
```
we get the prevous emp salary with a null for the 1st one (there's no prev emp)

lag takles args

lag(salary, 2, 0) looks 2 rows before and 0 is a default value

so we get 0, 0, 4000

lead is the same: rows following the current record

### use cases

if an employee salary is higher lower or equal than the previous

case when e.salary > lag(salary) over (....) then 'Higher'
when e.salary < lag(salary) over (....) then 'Lower'

# Application to the tree table

let's 1st add a measurement 
estimation of volume
circumference * height 
as Integer 
binned to 50 bins 


so we can compare the trees

also we need to handle null values and zero values better so that we can actually get volumes that make sense 

create table dimension
id
tree_id
name : height, circumference
measured : boolean 
value : (no NULL no 0)

and we add a flag : has dims ot trees when the tree has both height and circ

this assumes that super high measures are the rresult of a mistake from the human operator 
cm instead of meters

totally arbitrary
but we need good data

finally for trees that have absurd dimensions
rename height and circumference 
to raw_height and raw_circumference

modify height a such, given threshold value
if raw_height < threshold
height = raw_height
else 
height = raw_height / 10

repeat this operation until all heights are below threshold

same for circumference (threshold : circ / pi < 20)

Now we have trees with valid values 

for each arrondissement 
display column if tree height (calculated) is higher than 95 percentile

get the name, genre, sepecies ... of the highest tree in each arrondissement

are there species or genre, variety that come more ften than others

now do that for arrondissement and domain 



