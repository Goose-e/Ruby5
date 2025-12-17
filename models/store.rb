class Store < Sequel::Model
  set_dataset DB[:stores]
  plugin :validation_helpers
  one_to_many :inventories, class: 'Inventory', key: :store_id

  def validate
    validate_presence(:name)
    validate_presence(:city)
    validate_presence(:address)
    validate_min_length(:name, 3)
    validate_unique(:name)
  end
end
