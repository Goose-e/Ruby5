class BookGenre < Sequel::Model
  set_dataset DB[:book_genres]
  plugin :validation_helpers
  many_to_one :book
  many_to_one :genre

  def validate
    validate_presence(:book_id)
    validate_presence(:genre_id)
  end
end
