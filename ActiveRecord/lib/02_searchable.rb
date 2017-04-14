require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map { |el| "#{el} = ?"}.join(" AND ")
    result = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        "#{self.table_name}"
      WHERE
      #{where_line}
    SQL
    result.map { |info| self.new(info) }
  end
end

class SQLObject
  extend Searchable
end
