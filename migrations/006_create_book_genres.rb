DB.create_table(:book_genres) do |t|
  t.primary_key :id
  t.integer :book_id, null: false
  t.integer :genre_id, null: false
end
