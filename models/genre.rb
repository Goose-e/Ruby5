class Genre < Sequel::Model
  set_dataset DB[:genres]
  plugin :validation_helpers
  one_to_many :book_genres, class: 'BookGenre', key: :genre_id

  def validate
    validate_presence(:name)
    validate_presence(:description)
    validate_min_length(:description, 5)
    validate_unique(:name)
  end
end
