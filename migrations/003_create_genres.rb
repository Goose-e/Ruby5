DB.create_table(:genres) do |t|
  t.primary_key :id
  t.string :name, null: false
  t.string :description, null: false
  t.string :shelf_code
end
