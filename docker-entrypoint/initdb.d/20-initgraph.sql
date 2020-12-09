CREATE FUNCTION graph_path() 
RETURNS void AS $$
  BEGIN
  SET search_path = ag_catalog, "$user", public;
  END; 
$$ LANGUAGE plpgsql;

CREATE EXTENSION plpython3u;

CREATE FUNCTION load_graph_from_table(node_name text, source_table_name text, graph_name text DEFAULT null) 
RETURNS text AS $$
  import re
  def unquote_keys_json(query_result):
    regex = r'\"([^\"]*)\":'
    subst = '\\1:'
    return re.sub(regex, subst, query_result, 0, re.MULTILINE)
  def get_graph_name(graph_name):
    current_graph = graph_name
    if not graph_name:
      res = plpy.execute("SELECT current_setting('age.current_graph');");
      current_graph = res[0]["current_setting"]
    return current_graph
  def main(graph_name):
    row_count = 0  
    query = 'SELECT to_jsonb({src1}) FROM {src2}'.format(src1=source_table_name, src2=source_table_name)
    graph = get_graph_name(graph_name)
    for row in plpy.cursor(query):
      row_count = row_count + 1
      json_unquoted_keys = unquote_keys_json(row['to_jsonb'])
      graph_query = (("SELECT * from cypher('{graph_name}', ^^CREATE (a:{node_name} ".format(graph_name=graph, node_name=node_name) 
              + json_unquoted_keys  
              + ")^^) as (a agtype)")
              .replace("^", "$"))
      plpy.execute(graph_query)
    return "Successfully loaded {node} node from {tbl} table ({records} records)".format(node=node_name, tbl=source_table_name, records=row_count)
  return main(graph_name)
$$ LANGUAGE plpython3u;

-- Create and Load AGE extension
CREATE EXTENSION age;
LOAD 'age';
SET search_path = ag_catalog, "$user", public;


-- Create graph
SELECT create_graph('northwind_graph');

-- Set northwind_graph as default
SET age.current_graph='northwind_graph';

-- Create vertices/nodes from relational tables
SELECT load_graph_from_table('category', 'categories');
SELECT load_graph_from_table('customer', 'customers');
SELECT load_graph_from_table('employee', 'employees');
SELECT load_graph_from_table('order', 'orders');
SELECT load_graph_from_table('ordersdetail', 'orders_details');
SELECT load_graph_from_table('product', 'products');
SELECT load_graph_from_table('region', 'regions');
SELECT load_graph_from_table('shipper', 'shippers');
SELECT load_graph_from_table('supplier', 'suppliers');
SELECT load_graph_from_table('territory', 'territories');



-- Create edges/relationships
DO $$ BEGIN RAISE NOTICE 'CREATING Order Details Relationship'; END $$;

SELECT * FROM cypher('northwind_graph', $$
  MATCH (n:order),(m:product),(d:ordersdetail)
  WHERE n.orderid=d.orderid      
  AND m.productid=d.productid
  CREATE (n)-[r:ORDERS {unitprice:d.unitprice, quantity:d.quantity, discount:d.discount}]->(m)
  RETURN toString(count(r)) + ' relations created.'
$$) AS (a agtype);

DO $$ BEGIN RAISE NOTICE 'CREATING Employee-Mgr Relationship'; END $$;
SELECT * FROM cypher('northwind_graph', $$
  MATCH (n:employee),(m:employee)
  WHERE m.employeeid=n.reportto
  CREATE (n)-[r:REPORTS_TO]->(m) 
  RETURN toString(count(r)) + ' relations created.'
$$) AS (a agtype);

DO $$ BEGIN RAISE NOTICE 'CREATING Supplier Relationship'; END $$;
SELECT * FROM cypher('northwind_graph', $$
  MATCH (n:supplier),(m:product)
  WHERE m.supplierid=n.supplierid
  CREATE (n)-[r:SUPPLIES]->(m)
  RETURN toString(count(r)) + ' relations created.'
$$) AS (a agtype);

DO $$ BEGIN RAISE NOTICE 'CREATING Product Category Relationship'; END $$;
SELECT * FROM cypher('northwind_graph', $$
  MATCH (n:product),(m:category)
  WHERE n.categoryid=m.categoryid
  CREATE (n)-[r:PART_OF]->(m)
  RETURN toString(count(r)) + ' relations created.'
$$) AS (a agtype);

DO $$ BEGIN RAISE NOTICE 'CREATING Customer Purchase Relationship'; END $$;
SELECT * FROM cypher('northwind_graph', $$
  MATCH (n:customer),(m:order)
  WHERE m.customerid=n.customerid
  CREATE (n)-[r:PURCHASED]->(m)
  RETURN toString(count(r)) + ' relations created.'
$$) AS (a agtype);

DO $$ BEGIN RAISE NOTICE 'CREATING Employee-Sales Relationship'; END $$;
SELECT * FROM cypher('northwind_graph', $$
  MATCH (n:employee),(m:order)
  WHERE m.employeeid=n.employeeid
  CREATE (n)-[r:SOLD]->(m)
  RETURN toString(count(r)) + ' relations created.'
$$) AS (a agtype);