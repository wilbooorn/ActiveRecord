require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @data if @data
    data = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
    SQL
    @data = data.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        self.attributes[column]
      end
      define_method("#{column}=") do |val|
        self.attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
    # ...
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        "#{table_name}".*
      FROM
        "#{table_name}"
    SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map { |info| self.new(info) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        "#{table_name}".*
      FROM
        "#{table_name}"
      WHERE
        id = ?
    SQL
    result.empty? ? nil : self.new(result.first)
  end

  def initialize(params = {})
      params.each do |k, v|
        raise("unknown attribute '#{k}'") unless self.class.columns.include?(k.to_sym)
        self.send("#{k.to_sym}=", v)
      end
  end

  def attributes
    @attributes ||= {}
    # ...
  end

  def attribute_values
    self.class.columns.map { |el| self.send("#{el}") }
  end

  def insert
    cols = self.class.columns.drop(1)
    col_names = cols.join(", ")
    question_marks = (["?"] * cols.length).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
    INSERT INTO
      "#{self.class.table_name}" (#{col_names})
    VALUES
      (#{question_marks})

    SQL
    self.id = self.class.all.last.id
  end

  def update
    set_line = self.class.columns.drop(1).map { |el| "#{el} = ?"}.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values.rotate)
      UPDATE
        "#{self.class.table_name}"
      SET
        #{set_line}
      WHERE
        id = ?
    SQL

  end

  def save
    self.id ? update : insert
  end
end
