require_relative '../spec_helper'

RSpec.describe 'Store model' do
  it 'has seeded stores' do
    RSpec.expect(Store.all.size).to RSpec.eq(2)
  end

  it 'requires name' do
    store = Store.new(city: 'Test', address: '123 Lane')
    RSpec.expect(store.valid?).to RSpec.eq(false)
  end

  it 'requires city' do
    store = Store.new(name: 'Nameless', address: '123 Lane')
    RSpec.expect(store.valid?).to RSpec.eq(false)
  end

  it 'requires address' do
    store = Store.new(name: 'Nameless', city: 'Test')
    RSpec.expect(store.valid?).to RSpec.eq(false)
  end

  it 'enforces name uniqueness' do
    store = Store.new(name: 'Central Books', city: 'NY', address: 'Elsewhere')
    RSpec.expect(store.valid?).to RSpec.eq(false)
  end

  it 'creates a store' do
    store = Store.create(name: 'Corner Shop', city: 'Paris', address: '7 Rue de Test')
    RSpec.expect(Store.where(name: 'Corner Shop').first.city).to RSpec.eq('Paris')
  end

  it 'updates manager' do
    store = Store.where(name: 'Central Books').first
    store.update(manager: 'Carol')
    RSpec.expect(Store.where(name: 'Central Books').first.manager).to RSpec.eq('Carol')
  end

  it 'deletes a store' do
    store = Store.create(name: 'Temporary Store', city: 'Madrid', address: '1 Temp St')
    RSpec.expect { store.delete }.to RSpec.change(-> { Store.all.size }).by(-1)
  end

  it 'lists inventories' do
    store = Store.where(name: 'Central Books').first
    RSpec.expect(store.inventories.size).to RSpec.be_greater_than(0)
  end

  it 'groups stores by city' do
    grouped = Store.dataset.group_and_count(:city)
    RSpec.expect(grouped.map { |g| g[:city] }.sort).to RSpec.eq(['London', 'New York'])
  end
end
