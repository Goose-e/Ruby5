$LOAD_PATH.unshift(File.expand_path('..', __dir__))
require_relative '../db'

RSpec.configure do |config|
  config.before(:suite) do
    DataLoader.load_all(DB)
  end

  config.around(:each) do |example|
    DB.transaction(rollback: :always) do
      example.call
    end
  end
end
