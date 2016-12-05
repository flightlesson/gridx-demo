#! /usr/bin/env ruby

require 'optparse'
require 'pg'

FALLBACK_NPRODUCTS=1000
FALLBACK_NLOCATIONS=50
connection_options = {}
options = {nproducts:1000,nlocations:20,productprefix:'prod-',locationprefix:'loc-'}

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename $0} ]options]" +
    "\nPopulates a database with mock data. For example:" +
    "\n     #{File.basename $0} --verbose --createdb=./schema.sql --dbname=gridx" +
    "\nOptions include:"
  opts.on("-h","--help","Print this help message and exit.") do
    puts opts
    exit
  end
  opts.on("-v","--verbose","Verbose output.") do
    options[:verbose] = 1
  end
  opts.on('',"--noop","Don't actually do anything. Implies --verbose.") do
    options[:verbose] = 1
    options[:noop] = 1
  end
  opts.on('',"--seed=SEED","Random number generator seed.") do |v|
    options[:seed] = v
  end
  opts.on('',"--dbname=DBNAME","Database name.") do |v|
    connection_options[:dbname] = v
  end
  opts.on('',"--dbuser=USER","Database user.") do |v|
    connection_options[:dbuser] = v
  end
  opts.on('',"--createdb=SCHEMA","Drop and re-create db using SCHEMA before loading it with mock data") do |v|
    options[:createdb] = v
  end
  opts.on('',"--nproducts=N","Number of products to create. [#{options[:nproducts]}]") do |v|
    options[:nproducts] = v.to_i
  end
  opts.on('','--productprefix=PREFIX',"Prefix for generated product names. [#{options[:productprefix]}]") do |v|
    options[:productprefix] = v
  end
  opts.on('',"--nlocations=N","Number of locations to create. [#{options[:nlocations]}]") do |v|
    options[:nlocations] = v.to_i
  end
  opts.on('','--locationprefix=PREFIX',"Prefix for generated location names. [#{options[:locationprefix]}]") do |v|
    options[:locationprefix] = v
  end
end.parse!

if options[:createdb] then
  uopt = "-U #{connection_options[:dbuser]}" if connection_options[:dbuser]
  dbopt = "#{connection_options[:dbname]}" if connection_options[:dbname]
  cmd = "dropdb #{uopt} #{dbopt}"
  puts cmd if options[:verbose]
  r = system(cmd) unless options[:noop]
  puts "=> #{r.inspect}" if options[:verbose] && !options[:noop]

  cmd = "createdb #{uopt} #{dbopt}"
  puts cmd if options[:verbose]
  r = system(cmd) unless options[:noop]
  puts "=> #{r.inspect}" if options[:verbose] && !options[:noop]

  cmd = "cat #{options[:createdb]} | psql #{uopt} #{dbopt}"
  puts cmd if options[:verbose]
  r = system(cmd) unless options[:noop]
  puts "=> #{r.inspect}" if options[:verbose] && !options[:noop]
end

puts "PG::Connection.new(#{connection_options.inspect}})" if options[:verbose]
dbc= PG::Connection.new( connection_options ) unless options[:noop]
puts "=> #{dbc.inspect}" if options[:verbose] && !options[:noop]

lidray=[]
(1..options[:nlocations]).each do |i|
  name="#{options[:locationprefix]}#{i}"
  sql = "INSERT INTO locations (name) VALUES ('#{name}') RETURNING id"
  p sql if options[:verbose]
  unless options[:noop]
    r = dbc.exec(sql)
    p "=> #{r.inspect}, #{r[0].inspect}" if options[:verbose]
    lidray[i-1] = r[0]['id']
  end
end

prng = options[:seed] ? Random.new(options[:seed]) : Random.new()
(1..options[:nproducts]).each do |i|
  name="#{options[:productprefix]}#{i}"
  sql = "INSERT INTO products (name) VALUES ('#{name}') RETURNING id"
  p sql if options[:verbose]
  unless options[:noop]
    r = dbc.exec(sql)
    p "=> #{r.inspect}, #{r[0].inspect}" if options[:verbose]
    pid = r[0]['id']
    lidray.each do |lid|
      break if prng.rand(1.0) < 0.2
      sql = "INSERT INTO products_at_locations (product_id,location_id) VALUES (#{pid},#{lid})"
      p sql if options[:verbose]
      r = dbc.exec(sql)
      p "=> #{r.inspect}" if options[:verbose]
    end
  end
end

