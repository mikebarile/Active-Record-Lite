require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT *
      FROM #{table_name}
    SQL
    .first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.downcase.pluralize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{table_name}
    SQL
    parse_all(results)
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{table_name}
      WHERE id = #{id}
    SQL
    parse_all(results).first
  end

  def initialize(params = {})
    params.each do |param, value|
      unless self.class.columns.include?(param.to_sym)
        raise "unknown attribute '#{param}'"
      end
      send("#{param.to_sym}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map{|col| send(col)}
  end

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

  def save
    id ? update : insert
  end

  protected

  def self.parse_all(results)
    results.map do |result|
      new(result)
    end
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (['?'] * self.class.columns.length).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    send("#{:id}=", DBConnection.last_insert_row_id)
  end
end
