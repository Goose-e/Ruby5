require_relative '../spec_helper'

RSpec.describe 'Inventory model' do
  it 'counts seeded inventory rows' do
    RSpec.expect(Inventory.all.size).to RSpec.eq(4)
  end

  it 'requires book_id' do
    inventory = Inventory.new(store_id: 1, quantity: 1, last_restocked: '2025-01-01')
    RSpec.expect(inventory.valid?).to RSpec.eq(false)
  end

  it 'requires store_id' do
    inventory = Inventory.new(book_id: 1, quantity: 1, last_restocked: '2025-01-01')
    RSpec.expect(inventory.valid?).to RSpec.eq(false)
  end

  it 'validates non-negative quantity' do
    inventory = Inventory.new(book_id: 1, store_id: 1, quantity: -1, last_restocked: '2025-01-01')
    RSpec.expect(inventory.valid?).to RSpec.eq(false)
  end

  it 'creates inventory entry' do
    record = Inventory.create(book_id: 1, store_id: 2, quantity: 3, last_restocked: '2025-02-01')
    RSpec.expect(Inventory.where(id: record.id).first.quantity).to RSpec.eq(3)
  end

  it 'updates quantity' do
    record = Inventory.where(book_id: 2, store_id: 1).first
    record.update(quantity: 9)
    RSpec.expect(Inventory.where(book_id: 2, store_id: 1).first.quantity).to RSpec.eq(9)
  end

  it 'deletes inventory row' do
    record = Inventory.create(book_id: 3, store_id: 1, quantity: 2, last_restocked: '2025-02-02')
    RSpec.expect { record.delete }.to RSpec.change(-> { Inventory.all.size }).by(-1)
  end

  it 'associates to book and store' do
    record = Inventory.where(book_id: 1, store_id: 1).first
    RSpec.expect(record.book.title).to RSpec.eq('To Kill a Mockingbird')
    RSpec.expect(record.store.name).to RSpec.eq('Central Books')
  end

  it 'uses transactions for bulk updates' do
    result = DB.transaction do
      Inventory.where(book_id: 1).each { |inv| inv.update(quantity: inv.quantity + 1) }
      'done'
    end
    RSpec.expect(result).to RSpec.eq('done')
  end

  it 'rolls back on explicit rollback' do
    initial = Inventory.all.size
    DB.transaction(rollback: :always) do
      Inventory.create(book_id: 1, store_id: 1, quantity: 1, last_restocked: '2025-03-01')
    end
    RSpec.expect(Inventory.all.size).to RSpec.eq(initial)
  end
end
