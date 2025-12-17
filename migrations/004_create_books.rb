DB.create_table(:books) do |t|
  t.primary_key :id
  t.string :title, null: false
  t.decimal :price, null: false
  t.date :publication_date, null: false
  t.string :isbn, null: false
  t.integer :page_count, null: false
  t.integer :author_id, null: false
  t.integer :publisher_id, null: false
end
