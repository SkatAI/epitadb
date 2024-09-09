# With clause CTEs

sub query factoring 

-- fetch employees whose salary > avg(salary) of all employees

```sql
select *
from employee e
where e.salary > average_salary;
```

how to get average average salary

```sql
with average_salary  as
    (select avg(salary) from employee )
select *
from employee e, average_salary av
where e.salary > av.average_salary;
```
or mentionning the column s


```sql
with average_salary (avg_sal) as
    (select avg(salary) from employee )
select *
from employee e, average_salary av
where e.salary > av.avg_sal;
```

firt run teh with clause
store it in a temp table with alias temporary salary
its not a temp table
its only available during the query execution


cast as int to make it more friemdly
```sql
with average_salary (avg_sal) as
    (select cast(avg(salary)) as int from employee )
select *
from employee e, average_salary av
where e.salary > av.avg_sal;
```

# 2nd exemple

sales table 
store id, store name, product, qtty, cost

Find stores who's sales where better than the average sales across all stores

split query into several part
need ot find

- total sales per each stores: total_sales

- find avg of all sales across all stores
avg sales with respect to all the stores

- Find the stores where the totla sales of that store > totla sales of all stores

1st without the with clause

- total sales per each stores: total_sales

select s.store_id, sum(cost) as total_sales_per_store
from sales
group by s.store_id

- - find avg of all sales across all stores
avg sales with respect to all the stores

select cast(avg(total_sales_per_store) as int) as avg_sales_for_all_stores
from (select s.store_id, sum(cost) as total_sales_per_store
from sales
group by s.store_id) x

- Find the stores where the totla sales of that store > totla sales of all stores

select *
from (
    select s.store_id, sum(cost) as total_sales_per_store
    from sales
    group by s.store_id
) total_sales
join (
    select cast(avg(total_sales_per_store) as int) as avg_sales_for_all_stores
    from (select s.store_id, sum(cost) as total_sales_per_store
    from sales
    group by s.store_id x) avg_sales

)
on total_sales. total_sales_per_store > avg_sales. avg_sales_for_all_stores 


problems

multiple sub queries, 
using the same query multiple time

when you are peatntg same queries multiple times 
good scenario to use a with clause

with total_sales (store_id, total_sales_per_store) as 
    (    select s.store_id, sum(cost) as total_sales_per_store
    from sales
    group by s.store_id
    ),
    
-- extract avg sales : reuse totla sales justv defined
    avg_sales(avg_salesfor_all_stores) as
    (
        select cast(avg(total_sales_per_store) as int) as avg_sales_for_all_stores
        from total_sales
    )
-- main query
select *
from total_sales ts
join avg_sales av
on ts.total_sales_per_store > av. avg_sales_for_all_stores 


Same output but much cleaner code

- DRY
- final select is simple


Advantage of with clause
- more readable, easier debug
- no more temporary tables


different scenarios

when there's a subquery used mutiple times
readability
complex query are complex to understand => with clause simplifies 

to improve performance 
we will see that with EXPLAIN!




