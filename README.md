# Apache AGE Starter

This repository is designed to get people started using the Apache AGE plugin for Postgres. 

  - Utilizes Docker Compose to stand up a version of PostgreSQL 11 with Apache AGE compiled and installed [sorrell/agensgraph-extension](https://hub.docker.com/repository/docker/sorrell/agensgraph-extension)
  - Restores a Northwind DB on initial `docker-compose up`
  - Creates helper functions for loading graph nodes from existing tables
  - Creates vertices/edges from Northwind DB data on initial `docker-compose up`

## Getting started 

All you should have to do to get started is

  - Clone this repository
  - Run `docker-compose up`
  - Set your `search_path` in the client you connect with
  
To connect to the database, make sure you connect on port 5435, or change the docker-compose.yml to forward to a port you'd prefer. AGE should already be loaded.

Once you are connected to the database you need to set your `search_path` by either using the helper function `graph_path()` or use the `SET` cmd.

`SELECT graph_path();`

or

`SET search_path = ag_catalog, "$user", public;`

## Querying data

To query some of the data, utilize the `northwind_graph`. Below is an example query that displays a hierarchy of who reports to who.

```sql
SELECT * FROM cypher('northwind_graph', $$
  MATCH (n:employee)-[r:REPORTS_TO]->(m:employee)
  RETURN n.lastname, n.title, m.lastname, m.title
$$) AS (subord_lastname agtype, subord_title agtype, mgr_lastname agtype, mgr_title agtype);

------ RESULTS
-----------------+----------------------------+--------------+-------------------------
 subord_lastname |        subord_title        | mgr_lastname |        mgr_title
-----------------+----------------------------+--------------+-------------------------
 "Davolio"       | "Sales Representative"     | "Fuller"     | "Vice President, Sales"
 "Leverling"     | "Sales Representative"     | "Fuller"     | "Vice President, Sales"
 "Peacock"       | "Sales Representative"     | "Fuller"     | "Vice President, Sales"
 "Buchanan"      | "Sales Manager"            | "Fuller"     | "Vice President, Sales"
 "Suyama"        | "Sales Representative"     | "Buchanan"   | "Sales Manager"
 "King"          | "Sales Representative"     | "Buchanan"   | "Sales Manager"
 "Callahan"      | "Inside Sales Coordinator" | "Fuller"     | "Vice President, Sales"
 "Dodsworth"     | "Sales Representative"     | "Buchanan"   | "Sales Manager"
-----------------+----------------------------+--------------+-------------------------
(8 rows)
```

