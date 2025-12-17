$LOAD_PATH.unshift(File.expand_path(__dir__))
require_relative 'sequel'
require 'json'
require_relative 'lib/data_loader'

DB = Sequel.connect(ENV.fetch('DATABASE_URL', 'mock://book_store'))

Dir[File.join(__dir__, 'migrations', '*.rb')].sort.each { |f| require_relative f }
Dir[File.join(__dir__, 'models', '*.rb')].sort.each { |f| require_relative f }

DataLoader.load_all(DB)

if $PROGRAM_NAME == __FILE__
  puts "Database loaded"
  puts "Authors: #{Author.all.size}, Books: #{Book.all.size}, Stores: #{Store.all.size}"
end
