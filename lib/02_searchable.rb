require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{self.table_name}
      WHERE #{format_params(params)}
    SQL

    results.map do |res|
      self.new(res)
    end
  end

  def format_params(params)
    str = ""
    params.each do |k, v|
      str += "#{k} = '#{v}' AND "
    end

    str[0..-5]
  end
end

class SQLObject
  extend Searchable
end
