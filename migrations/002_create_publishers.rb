DB.create_table(:publishers) do |t|
  t.primary_key :id
  t.string :name, null: false
  t.string :country, null: false
  t.integer :founded_year, null: false
  t.string :website
end
