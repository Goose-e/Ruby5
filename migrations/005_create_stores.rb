DB.create_table(:stores) do |t|
  t.primary_key :id
  t.string :name, null: false
  t.string :city, null: false
  t.string :address, null: false
  t.string :manager
end
