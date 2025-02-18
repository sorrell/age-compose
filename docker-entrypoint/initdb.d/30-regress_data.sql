SET search_path = ag_catalog, "$user", public;

SET age.current_graph='northwind_graph';

SELECT create_vlabel('northwind_graph','City');

SELECT load_labels_from_file('northwind_graph', 'City',
    '/age/regress/age_load/data/cities.csv', true);

SELECT create_vlabel('northwind_graph','Country');
SELECT load_labels_from_file('northwind_graph',
                             'Country',
                             '/age/regress/age_load/data/countries.csv');

SELECT create_elabel('northwind_graph','has_city');
SELECT load_edges_from_file('northwind_graph', 'has_city',
     '/age/regress/age_load/data/edges.csv');