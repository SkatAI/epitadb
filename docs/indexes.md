# Indexes

https://www.postgresql.org/docs/16/indexes.html

Before we go further into understanding query plans let's talk about indexes

PostgreSQL automatically creates indexes that are needed for the system to behave correctly.
When you declare a unique constraint, a primary key constraint  PostgreSQL creates the associated index. 

An index only provides another access method to the data, one that is faster than a sequential scan in most cases.


An index in PostgreSQL is a data structure that improves the speed of data retrieval operations on database tables. It acts like a lookup table, allowing the database engine to find data quickly without scanning the entire table.


## Index Types

https://www.postgresql.org/docs/current/indexes.html

PostgreSQL provides several index types: B-tree, Hash, GiST, SP- GiST, GIN and BRIN. Each index type uses a different algorithm that is best suited to different types of queries. 

By default, the CREATE INDEX command creates B-tree indexes, which fit the most common situations.

Yiou create an index with 

```sql
CREATE INDEX index_name ON table_name (column_name);
```

that creates a B-Tree indx 

 create anopther type of index with USING
 
```sql
CREATE INDEX index_name ON table_name using HASH (column_name);
```


Storage: Indexes are stored separately from the table data.
When data in the indexed column(s) is modified, the index is automatically updated.

Read vs. Write trade-off: Indexes speed up read operations but can slow down write operations due to the overhead of updating the index along with the table.

All indexes in PostgreSQL are secondary indexes, meaning that each index is stored separately from the table's main data area (which is called the table's **heap** in PostgreSQL terminology). This means that in an ordinary index scan, each row retrieval requires fetching data from both the index and the heap. Furthermore, while the index entries that match a given indexable WHERE condition are usually close together in the index, the table rows they reference might be anywhere in the heap. The heap-access portion of an index scan thus involves a lot of random access into the heap, which can be slow

so index are used when they return a small set of rows


**Why not index everything ?**

An index duplicates data in a specialized format made to optimise a certain type of searches. This duplicated data set is still ACID compliant: at COMMIT;
Chapter 8 IndexingStrategy|71
  
Chapter 8 IndexingStrategy|72 time, every change that is made it to the main tables of your schema must have
made it to the indexes too.
As a consequence, each index adds write costs to your DML queries: insert, up-
date and delete now have to maintain the indexes too, and in a transactional way.
That’s why we have to define a global indexing strategy. Unless you have infinite IO bandwidth and storage capacity, it is not feasible to index everything in your database.




### B-Tree or balanced tree
  
deep dive : https://www.postgresql.org/docs/current/btree.html  
  
Balanced indexes are the most common used, by a long shot, because they are very efficient and provide an algorithm that applies to most cases. PostgreSQL implementation of the B-Tree index support is best in class and has been optimized to handle concurrent read and write operations.

**from the doc**
B-trees can handle **equality** and **range** queries on data that can be sorted into some ordering. 

B-trees are involved in a comparison filters that use one of these operators: <   <=   =   >=   >

Constructs equivalent to combinations of these operators, such as BETWEEN and IN, can also be implemented with a B-tree index search. Also, an IS NULL or IS NOT NULL condition on an index column can be used with a B-tree index.

In many cases, B-tree indexes (the default in PostgreSQL) are more versatile and can handle a wider range of query types. 

## Hash index

Hash indexes store a 32-bit hash code derived from the value of the indexed column. Hence, such indexes can only handle simple equality comparisons. The query planner will consider using a hash index whenever an indexed column is involved in a comparison using the equal operator: 

=

#### what is a hash code ?

Very important notion in computer science and data science
basically a hash code / hash for short is a unique string associated to a data sample.
each sample (record) has a unique hash string. 
It's super efficient to quickly enable equality filtering  

It allows to get a unique ID for a set of records


A hash code is a numeric representation of data, typically a fixed-length value, produced by applying a hash function to the original data.

A hash function is an algorithm that takes an input (or 'message') and returns a fixed-size string of bytes. The output is called the hash value, hash code, digest, or simply hash.

Deterministic: The same input always produces the same hash code.
Fast to compute: It should be quick to calculate the hash code.
Uniform distribution: Hash codes should be evenly distributed across the possible range.
Avalanche effect: A small change in the input should result in a significantly different hash code.

Usage in hash indexes:

PostgreSQL applies a hash function to the indexed column's value.
The resulting 32-bit hash code is used as a key in the index structure.
This allows for very fast lookups when searching for exact matches.

Advantages:

Fast for equality comparisons
Compact storage (fixed size regardless of input data size)


Limitations:

Not suitable for range queries or sorting
Potential for collisions (different values producing the same hash code)


in python:

```python
import hashlib

def get_hash_code(data):
    # Create a SHA-256 hash object
    hash_object = hashlib.sha256()
    # Update the hash object with the bytes of the input string
    hash_object.update(data.encode())
    # Get the hexadecimal representation of the hash
    hex_dig = hash_object.hexdigest()
    # Convert the first 8 characters of the hex to an integer (32-bit)
    return int(hex_dig[:8], 16)

# Example usage
print(get_hash_code("Hello, World!"))  # This will print a 32-bit integer
```

so a hash index is great for 



1. Equality comparisons:
   Hash indexes excel when you frequently perform exact match queries. ideal for columns where you often use the "=" operator.

2. High-cardinality data:
   Data with many unique values benefits most from hash indexes. This includes:
   - Unique identifiers (e.g., UUIDs, customer IDs)
   - Email addresses
   - Usernames

3. Fixed-length data:
   While hash indexes can work with variable-length data, they're particularly efficient with fixed-length data types like:
   - Integers
   - Fixed-length character fields
   - Dates and timestamps

4. Large tables:
   Hash indexes can provide significant performance improvements for equality searches on large tables.

5. Read-heavy workloads:
   Since hash indexes are optimized for lookups, they're most beneficial in scenarios with many read operations and fewer writes.

6. Memory-resident data:
   Hash indexes perform best when they can fit entirely in memory.

Examples where hash indexes are useful:

- User authentication: Quickly finding a user by their unique username or email.
- Product lookups: Finding a product by its SKU or unique identifier.
- Session management: Retrieving session data based on a session ID.
- Caching: Using a hash index on cache keys for fast retrieval.

Hash indexes have limitations:

- They don't support range queries or sorting operations.
- They're not suitable for partial matches or pattern matching (like LIKE queries).
- They don't support multi-column indexes.

Hash indexes are most beneficial when you have a specific need for very fast equality comparisons on a single column.


CREATE INDEX name ON table USING HASH (column);


### GiST, or generalized search tree

This access method implements an more general algorithm that again comes from research activities. The GiST Indexing Project from the University of California Berkeley 
http://gist.cs.berkeley.edu

is described in the following terms:

The GiST project studies the engineering and mathematics behind content-based indexing for massive amounts of complex content.

Its implementation in PostgreSQL allows support for 2-dimensional data types such as the geometry point or the ranges data types.

### GIN, or generalized inverted index

GIN is designed for handling cases where the items to be indexed are com-posite values, and the queries to be handled by the index need to search for element values that appear within the composite items. 

For example, the items could be documents, and the queries could be searches for documents containing specific words.

GIN indexes are “inverted indexes” which are appropriate for data values that contain multiple component values, such as arrays. An inverted index contains a separate entry for each component value. 

Such an index can efficiently handle queries that test for the presence of specific component values.
The GIN access method is the foundation for the PostgreSQL Full Text Search support.

https://www.postgresql.org/docs/current/static/textsearch-intro.html


### Bloom filters

A Bloom filter is a space-efficient data structure that is used to test whether an element is a member of a set. In the case of an index access method, it allows fast exclusion of non-matching tuples via signatures whose size is determined at index creation.

This type of index is most useful when a table has many attributes and queries test arbitrary combinations of them. A traditional B-tree index is faster than a Bloom index, but it can require many B-tree indexes to support all possible queries where one needs only a single Bloom index. 

Bloom indexes only support equality queries, whereas B-tree indexes can also perform inequality and range searches.

The Bloom filter index is implemented as a PostgreSQL extension starting in PostgreSQL 9.6, and so to be able to use this access method it’s necessary to first create extension bloom.


Bloom indexes and BRIN indexes are mostly useful when covering mutliple columns. In the case of Bloom indexes, they are useful when the queries themselves are referencing most or all of those columns in equality comparisons.

see https://www.postgresql.org/docs/current/indexes.html



# Order by 
only B-tree can produce sorted output

the other index types return matching rows in an unspecified, implementation-dependent order.

The planner will consider satisfying an ORDER BY specification either by scanning an available index that matches the specification, or by scanning the table in physical order and doing an explicit sort.

BUT:  For a query that requires scanning a large fraction of the table, an explicit sort is likely to be faster than using an index because it requires less disk I/O due to following a sequential access pattern. 

Indexes are more useful when only a few rows need be fetched. 

An important special case is ORDER BY in combination with LIMIT n: an explicit sort will have to process all the data to identify the first n rows, but if there is an index matching the ORDER BY, the first n rows can be retrieved directly, without scanning the remainder at all.


B-tree indexes store their entries in ascending order with nulls last 
 
You can adjust the ordering of a B-tree index by including the options ASC, DESC, NULLS FIRST, and/or NULLS LAST when creating the index; 
 
```sql
CREATE INDEX test2_info_nulls_low ON test2 (info NULLS FIRST);
CREATE INDEX test3_desc_index ON test3 (id DESC NULLS LAST);
```


### Unique Indexes

Indexes can also be used to enforce uniqueness of a column's value, or the uniqueness of the combined values of more than one column.

CREATE UNIQUE INDEX name ON table (column [, ...]) [ NULLS [ NOT ] DISTINCT ];

Currently, only B-tree indexes can be declared unique.

PostgreSQL automatically creates a unique index when a unique constraint or primary key is defined for a table.
so no need to create a unqieu index on unique columns


# iNdex only Scans

The query must reference only columns stored in the index. For example, given an index on columns x and y of a table that also has a column z, these queries could use index-only scans:

SELECT x, y FROM tab WHERE x = 'key';
SELECT x FROM tab WHERE x = 'key' AND y < 42;

but these queries could not:

SELECT x, z FROM tab WHERE x = 'key';
SELECT x FROM tab WHERE x = 'key' AND z < 42;


The index type must support index-only scans. B-tree indexes always do. GiST and SP-GiST indexes support index-only scans for some operator classes but not others. Other index types have no support. The underlying requirement is that the index must physically store, or else be able to reconstruct, the original data value for each index entry
 

# Examining Index Usage

https://www.postgresql.org/docs/current/indexes-examine.html

it is important to check which indexes are actually used by the real-life query workload  with the EXPLAIN command;


It is difficult to formulate a general procedure for determining which indexes to create. There are a number of typical cases that have been shown in the examples throughout the previous sections. A good deal of experimentation is often necessary. 

tips for that:

* Always run ANALYZE first. This command collects statistics about the distribution of the values in the table. This information is required to estimate the number of rows returned by a query, which is needed by the planner to assign realistic costs to each possible query plan. In absence of any real statistics, some default values are assumed, which are almost certain to be inaccurate. Examining an application's index usage without having run ANALYZE is therefore a lost cause. 

**Real data vs test data**: 
* Use real data for experimentation. Using test data for setting up indexes will tell you what indexes you need for the test data, but that is all.

* It is especially fatal to use very small test data sets. While selecting 1000 out of 100000 rows could be a candidate for an index, selecting 1 out of 100 rows will hardly be, because the 100 rows probably fit within a single disk page, and there is no plan that can beat sequentially fetching 1 disk page.

* Also be careful when making up test data, which is often unavoidable when the application is not yet in production. Values that are very similar, completely random, or inserted in sorted order will skew the statistics away from the distribution that real data would have.

**force index use**:
When indexes are not used, it can be useful for testing to force their use. There are run-time parameters that can turn off various plan types (see Section 20.7.1). For instance, turning off sequential scans (enable_seqscan) and nested-loop joins (enable_nestloop), which are the most basic plans, will force the system to use a different plan. If the system still chooses a sequential scan or nested-loop join then there is probably a more fundamental reason why the index is not being used; for example, the query condition does not match the index. (What kind of query can use what kind of index is explained in the previous sections.)

If forcing index usage does use the index, then there are two possibilities: Either the system is right and using the index is indeed not appropriate, or the cost estimates of the query plans are not reflecting reality. So you should time your query with and without indexes. The EXPLAIN ANALYZE command can be useful here.

... 

# Practice

Here's a complex query on the treesdb database

Explain (analyze) the query 
and experiment with multiple indexes 
interpret the results and timing gains if any 


