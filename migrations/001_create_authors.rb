DB.create_table(:authors) do |t|
  t.primary_key :id
  t.string :name, null: false
  t.string :country, null: false
  t.integer :birth_year, null: false
  t.string :biography, null: false
end
