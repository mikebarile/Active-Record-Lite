# Active Record Lite

## Description

The goal of this project was to develop a simplified, lightweight version of the Rails library gem Active Record. I built Active Record Lite from the ground up using metaprogramming techniques and adding key functionality from the original gem. These functionalities include:
- SQL objects
- "Where" searches
- Object relationships

## Implementation Details

#### SQL Objects

The SQL objects implemented in AR Lite are very similar to the Active Record objects implemented in Active Record. They include the following methods:
- ::all - returns all instances of SQL object class
- ::find(id) - returns instance of SQL object class with provided id
- ::columns - returns SQL object class's columns
- ::table_name - returns SQL object class's table name
- ::table_name=(table_name) - renames SQL object's table name
- #save - saves SQL object to database
- #attributes - lists SQL object's attributes
- #attribute_values - lists SQL object's attribute values
- #update - Updates SQL object's attributes

Many of these methods rely on DBConnection (found in db_connection.rb) to interact with the database. An example is the update method:
```
def update
  set = self.class.columns.map{ |col| "#{col} = ?"}.join(", ")

  DBConnection.execute(<<-SQL, *attribute_values, id)
  UPDATE
    #{self.class.table_name}
  SET
    #{set}
  WHERE
    id = ?
  SQL

  send("#{:id}=", DBConnection.last_insert_row_id)
end
```

#### "Where" Searches
In addition, I've added a separate "Searchable" module to enable ::where searches across SQL object classes. The code for this module can be found below:
```
module Searchable
  def where(params)
    where_line = params.map{ |key, _| "#{key} = ?"}.join(" AND ")
    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT *
      FROM #{table_name}
      WHERE #{where_line}
    SQL
    parse_all(results)
  end
end
```

#### Object relationships
In addition to the above functionality, I've also implemented Active Record associates through the Associatable module. This module enables different SQL object classes to be related to one another through the traditional Active Record relationships such as "belongs_to" and "has_many". To illustrate this, I've included code for #belongs_to below:
```
def belongs_to(name, options = {})
  options = BelongsToOptions.new(name, options)
  assoc_options[name] = options
  define_method(name) do
    foreign_key = send(options.foreign_key)
    target_class = options.model_class
    params = {options.primary_key => foreign_key}
    target_class.where(params).first
  end
end
```
