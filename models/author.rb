class Author < Sequel::Model
  set_dataset DB[:authors]
  plugin :validation_helpers
  one_to_many :books, class: 'Book', key: :author_id

  def validate
    validate_presence(:name)
    validate_presence(:country)
    validate_presence(:biography)
    validate_min_length(:biography, 10)
    validate_unique(:name)
    validate_numeric(:birth_year, gte: 1800)
  end
end
