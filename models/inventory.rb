class Inventory < Sequel::Model
  set_dataset DB[:inventories]
  plugin :validation_helpers
  many_to_one :book
  many_to_one :store

  def validate
    validate_presence(:book_id)
    validate_presence(:store_id)
    validate_numeric(:quantity, gte: 0)
  end
end
