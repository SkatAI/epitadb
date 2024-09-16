# Session 3 

## Last time 

* dumping and restoring database (Wow, such restore, much excite)

![](https://imgflip.com/i/93mksr)


* Transformed the basic ```trees``` table, directly loaded from the csv file
    * Looked at ```idbase``` and decided it was not a good candidate for a primary key 
    * Created a new primary key ```id``` in the trees table
    * Looked at the sequence that was created along the primary key
    * Modified the data type of some columns: 
        * remarkable as Boolean
        * geo_point_2d as geolocation with the POINT data type
    * Added a ```diameter``` column

## Today

We look at **normalization** and how to properly design a database. 

To design a **database** at this point means what data goes into what table, with what columns. In short what goes where.

It's the basis before  all the other design decision we'll have to make.

We look at 

* ERD
* OLAP vs OLTP databases
* Normalization and Denormalization
* Normal Forms 

## Appplication

And then we normalize the **treesdb_v02** database.

It comes down to a 5 step process

* identify the entities to export to a dedicated table
* transfer the columns data
* reconcile the trees table with the new table
* check
* remove the columns

and throughout this process we'll write many different types of queries.

## Trouble installing and connecting 

At this point, you should be able to connect to the postgresql server: 

* connect locally with the postgres user or the local user (mac)
    * ```psql -U postgres -d postgres``` (Windows)
    * ```psql -U <username> -d postgres``` (Mac)
* connect to the **remote** server with the epita user 
    * ```psql -h <ip_address> -U epita -d postgres```
    * *I'll give you the ip address of the remote server*
* start stop monitor the server on your local machine (see below)
* load the dump file with 
    * ```pg_restore``` on the command line (iTerm or termimal on Mac or powershell on Windows)
    * in pgAdmin (not tested )


To check if the server is running on your local machine
### On Windows

* launch a powershell terminal 
    * Win + X
    * select terminal (Admin)
* use ```pg_ctl``` :
    * start : ```pg_ctl start```
    * stop : ```pg_ctl stop```
    * restart : ```pg_ctl restart```
    * check status: ```pg_ctl status```


### On mac
In a terminal window:
* brew services start | stop | restart postgres@16
* brew services info postgres@16

sometimes you have to use ```sudo``` to start. 

# Let's go

get the course pdf from the githu repo in 

epitadb\docs\03\S3-database-design-normalization.pdf

