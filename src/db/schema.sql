CREATE TABLE products (
  id SERIAL PRIMARY KEY
  ,name TEXT NOT NULL UNIQUE
);

CREATE TABLE locations (
  id SERIAL PRIMARY KEY
  ,name TEXT NOT NULL UNIQUE
);

CREATE TABLE products_at_locations (
  product_id INT NOT NULL REFERENCES products(id)
  ,location_id INT NOT NULL REFERENCES locations(id)
  ,arrival_time TIMESTAMP NOT NULL DEFAULT now()
);
