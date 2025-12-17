class Publisher < Sequel::Model
  set_dataset DB[:publishers]
  plugin :validation_helpers
  one_to_many :books, class: 'Book', key: :publisher_id

  def validate
    validate_presence(:name)
    validate_presence(:country)
    validate_numeric(:founded_year, gte: 1400)
    validate_min_length(:name, 3)
    validate_unique(:name)
  end
end
