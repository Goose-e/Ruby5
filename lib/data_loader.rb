require 'json'

class DataLoader
  def self.load_all(db)
    new(db).load_all
  end

  def initialize(db)
    @db = db
  end

  def load_all
    db.transaction do
      %i[authors publishers genres books stores book_genres inventories].each do |table|
        load_table(table)
      end
    end
  end

  private

  attr_reader :db

  def load_table(name)
    path = File.join(__dir__, '..', 'json_data', "#{name}.json")
    return unless File.exist?(path)

    db.tables[name]&.clear
    data = JSON.parse(File.read(path))
    data.each do |attrs|
      db[name].insert(symbolize_keys(attrs))
    end
  end

  def symbolize_keys(hash)
    hash.transform_keys { |k| k.to_sym }
  end
end
