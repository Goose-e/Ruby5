require 'date'
require 'forwardable'

module Sequel
  class Rollback < StandardError; end

  def self.connect(_url = nil)
    Database.new
  end

  class Database
    attr_reader :tables, :schemas

    def initialize
      @tables = {}
      @schemas = {}
      @transactions = []
    end

    def create_table(name)
      builder = TableBuilder.new
      yield builder
      @schemas[name] = builder.columns
      @tables[name] ||= []
    end

    def drop_table(name)
      @schemas.delete(name)
      @tables.delete(name)
    end

    def [](name)
      Dataset.new(self, name)
    end

    def transaction(options = {})
      snapshot = Marshal.load(Marshal.dump([@tables, @schemas]))
      @transactions << snapshot
      begin
        result = yield
        raise Rollback if options[:rollback] == :always
        result
      rescue Rollback
        @tables, @schemas = snapshot
      rescue StandardError
        @tables, @schemas = snapshot
        raise
      ensure
        @transactions.pop
      end
    end

    def schema(name)
      @schemas[name]
    end
  end

  class TableBuilder
    attr_reader :columns

    def initialize
      @columns = {}
    end

    def primary_key(name, type = :integer, opts = {})
      column(name, type, opts.merge(primary_key: true, auto_increment: true))
    end

    def column(name, type, opts = {})
      @columns[name] = { type: type }.merge(opts)
    end

    def string(name, opts = {})
      column(name, :string, opts)
    end

    def integer(name, opts = {})
      column(name, :integer, opts)
    end

    def decimal(name, opts = {})
      column(name, :decimal, opts)
    end

    def float(name, opts = {})
      column(name, :float, opts)
    end

    def date(name, opts = {})
      column(name, :date, opts)
    end

    def boolean(name, opts = {})
      column(name, :boolean, opts)
    end
  end

  class Dataset
    extend Forwardable
    attr_reader :db, :table

    def initialize(db, table, rows = nil)
      @db = db
      @table = table
      @rows = rows
    end

    def all
      current_rows.map { |r| r.dup }
    end

    def insert(values)
      row = values.dup
      schema = db.schema(table)
      pk = schema.keys.find { |k| schema[k][:primary_key] }
      if pk && !row.key?(pk)
        row[pk] = next_id_for(pk)
      end
      current_rows << row
      row[pk]
    end

    def where(conditions = nil, &block)
      filtered = if block
                   current_rows.select(&block)
                 elsif conditions
                   current_rows.select do |row|
                     conditions.all? { |k, v| row[k] == v }
                   end
                 else
                   current_rows
                 end
      Dataset.new(db, table, filtered)
    end

    def first
      current_rows.first&.dup
    end

    def update(values)
      count = 0
      current_rows.each do |row|
        values.each { |k, v| row[k] = v }
        count += 1
      end
      count
    end

    def delete
      count = current_rows.size
      db.tables[table] -= current_rows
      count
    end

    def count
      current_rows.size
    end

    def group_and_count(column)
      grouped = current_rows.group_by { |r| r[column] }
      grouped.map { |key, rows| { column => key, count: rows.size } }
    end

    def order(column)
      Dataset.new(db, table, current_rows.sort_by { |r| r[column] })
    end

    def map(&block)
      current_rows.map(&block)
    end

    private

    def current_rows
      @rows || db.tables[table] || []
    end

    def next_id_for(pk)
      (current_rows.map { |r| r[pk] }.max || 0) + 1
    end
  end

  class Model
    def self.set_dataset(dataset)
      @dataset = dataset
    end

    def self.dataset
      @dataset
    end

    def self.all
      dataset.all.map { |row| new(row) }
    end

    def self.first
      row = dataset.first
      row && new(row)
    end

    def self.create(attrs = {})
      record = new(attrs)
      record.save
      record
    end

    def self.where(conditions = nil, &block)
      dataset.where(conditions, &block).all.map { |row| new(row) }
    end

    def self.plugin(name)
      include ValidationHelpers if name == :validation_helpers
    end

    def self.many_to_one(name, opts = {})
      define_method(name) do
        klass = Object.const_get(opts[:class] || self.class.camelize(name, singularize: true))
        fk = opts[:key] || "#{name}_id".to_sym
        row = klass.dataset.where(id: send(fk)).first
        row && klass.new(row)
      end
    end

    def self.one_to_many(name, opts = {})
      define_method(name) do
        klass = Object.const_get(opts[:class] || self.class.camelize(name.to_s.sub(/s\z/, '').to_sym))
        fk = opts[:key] || "#{self.class.name.split('::').last.downcase}_id".to_sym
        klass.dataset.where(fk => id).map { |row| klass.new(row) }
      end
    end

    def self.many_to_many(name, opts = {})
      define_method(name) do
        join_table = opts[:join_table]
        left_key = opts[:left_key] || "#{self.class.name.split('::').last.downcase}_id".to_sym
        right_key = opts[:right_key] || "#{name.to_s.sub(/s\z/, '')}_id".to_sym
        target_class = Object.const_get(opts[:class] || self.class.camelize(name, singularize: true))

        join_rows = self.class.dataset.db[join_table].where(left_key => id).all
        target_ids = join_rows.map { |jr| jr[right_key] }
        target_class.dataset.where { |row| target_ids.include?(row[:id]) }.all.map { |row| target_class.new(row) }
      end
    end

    def self.camelize(symbol, singularize: false)
      base = symbol.to_s
      base = base.sub(/s\z/, '') if singularize
      base.split('_').map(&:capitalize).join
    end

    attr_reader :values

    def initialize(attrs = {})
      @values = attrs.dup
      @errors = Hash.new { |h, k| h[k] = [] }
    end

    def id
      @values[:id]
    end

    def [](key)
      @values[key]
    end

    def []=(key, value)
      @values[key] = value
    end

    def errors
      @errors
    end

    def method_missing(name, *args, &block)
      key = name.to_s.sub(/=$/, '').to_sym
      if values.key?(key)
        if name.to_s.end_with?('=')
          values[key] = args.first
        else
          values[key]
        end
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      key = name.to_s.sub(/=$/, '').to_sym
      values.key?(key) || super
    end

    def valid?
      errors.clear
      validate
      errors.empty?
    end

    def validate; end

    def save
      raise "Validation failed: #{errors}" unless valid?
      if id
        self.class.dataset.where(id: id).update(values)
      else
        new_id = self.class.dataset.insert(values)
        values[:id] = new_id
      end
      self
    end

    def update(attrs = {})
      attrs.each { |k, v| values[k] = v }
      save
    end

    def delete
      self.class.dataset.where(id: id).delete
    end
  end

  module ValidationHelpers
    def validate_presence(field)
      value = values[field]
      errors[field] << 'cannot be empty' if value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end

    def validate_unique(field)
      existing = self.class.dataset.where(field => values[field]).first
      if existing && existing[:id] != values[:id]
        errors[field] << 'is already taken'
      end
    end

    def validate_numeric(field, opts = {})
      value = values[field]
      return if value.nil?
      errors[field] << 'is not a number' unless value.is_a?(Numeric)
      errors[field] << 'is too small' if opts[:gte] && value < opts[:gte]
      errors[field] << 'is too large' if opts[:lte] && value > opts[:lte]
    end

    def validate_min_length(field, length)
      value = values[field]
      errors[field] << "must be at least #{length} characters" if value.nil? || value.to_s.length < length
    end

    def validate_includes(field, list)
      value = values[field]
      errors[field] << 'is not included in the list' unless list.include?(value)
    end
  end
end
