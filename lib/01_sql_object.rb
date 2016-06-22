require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    if @columns.nil?
      cols = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{self.table_name}
      SQL

      @columns = cols[0].map do |col|
        col.to_sym
      end
    else
      @columns
    end
  end

  def self.finalize!

    columns.each do |col|

      define_method(col) do
        @attributes[col]
      end

      define_method("#{col}=") do |val|
        attributes[col] = val
      end

    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    class_name = self.name
    class_chars = class_name.chars
    tab_name = ""

    class_chars.each_with_index do |ch, idx|
      if !(/[[:upper:]]/.match(ch).nil?)
        if idx - 1 >= 0
          tab_name += '_'
        end
        tab_name += ch.downcase
      else
        tab_name += ch
      end
    end

    tab_name += 's'

    @table_name = tab_name
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
                SELECT *
                FROM #{self.table_name}
              SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    res = results.map do |row|
      self.new(row)
    end
  end

  def self.find(id)
    found = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{self.table_name}
      WHERE id = #{id}
    SQL

    if found.empty? || found.nil?
      nil
    else
      self.new(found[0])
    end
  end

  def initialize(params = {})
    cols = self.class.columns
    params.each do |k,v|
      if cols.include?(k.to_sym)
        meth = k.to_s + '='
        self.send(meth, v)
      else
        raise "unknown attribute '#{k.to_s}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    vals = []
    attributes.each do |k, v|
      vals << v
    end
    vals
  end

  def insert
    DBConnection.execute(<<-SQL,attribute_values)
      INSERT INTO #{self.class.table_name} (#{self.class.columns.drop(1).join(",")})
      VALUES (#{get_question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def get_question_marks
    str = '?,' * (self.class.columns.size - 1)
    str[0..-2]
  end

  def update
    DBConnection.execute(<<-SQL, syntax_values)
      UPDATE #{self.class.table_name}
      SET #{update_set_syntax}
      WHERE id = #{self.id}
    SQL
  end

  def syntax_values
    attribute_values.drop(1)
  end

  def update_set_syntax
    str = ''
    self.class.columns.drop(1).each do |val|
      str += val.to_s + ' = ' + ' ?, '
    end
    str[0..-3]
  end

  def save
    if self.attributes.empty?
      insert
    else
      update
    end
  end
end
