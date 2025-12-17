DB.create_table(:inventories) do |t|
  t.primary_key :id
  t.integer :book_id, null: false
  t.integer :store_id, null: false
  t.integer :quantity, null: false
  t.date :last_restocked, null: false
end
