class Book < Sequel::Model
  set_dataset DB[:books]
  plugin :validation_helpers
  many_to_one :author
  many_to_one :publisher
  many_to_many :genres, join_table: :book_genres, right_key: :genre_id
  one_to_many :inventories, class: 'Inventory', key: :book_id

  def validate
    validate_presence(:title)
    validate_presence(:isbn)
    validate_presence(:publication_date)
    validate_numeric(:price, gte: 0)
    validate_numeric(:page_count, gte: 1)
    validate_min_length(:title, 3)
    validate_unique(:isbn)
  end
end
