require_relative '../spec_helper'

RSpec.describe 'Publisher model' do
  it 'loads seeded publishers' do
    RSpec.expect(Publisher.all.size).to RSpec.eq(2)
  end

  it 'validates presence of name' do
    publisher = Publisher.new(country: 'USA', founded_year: 2000)
    RSpec.expect(publisher.valid?).to RSpec.eq(false)
    RSpec.expect(publisher.errors[:name].any?).to RSpec.be_truthy
  end

  it 'validates unique name' do
    publisher = Publisher.new(name: 'Penguin Books', country: 'USA', founded_year: 2001)
    RSpec.expect(publisher.valid?).to RSpec.eq(false)
  end

  it 'validates founded year range' do
    publisher = Publisher.new(name: 'Ancient', country: 'Egypt', founded_year: 1000)
    RSpec.expect(publisher.valid?).to RSpec.eq(false)
    RSpec.expect(publisher.errors[:founded_year].any?).to RSpec.be_truthy
  end

  it 'creates publisher successfully' do
    publisher = Publisher.create(name: 'Orbit', country: 'USA', founded_year: 1974, website: 'https://example.com')
    RSpec.expect(Publisher.where(name: 'Orbit').first.country).to RSpec.eq('USA')
  end

  it 'updates website' do
    publisher = Publisher.where(name: 'HarperCollins').first
    publisher.update(website: 'https://updated.example.com')
    RSpec.expect(Publisher.where(name: 'HarperCollins').first.website).to RSpec.eq('https://updated.example.com')
  end

  it 'deletes publisher' do
    publisher = Publisher.create(name: 'Temporary Pub', country: 'USA', founded_year: 2020)
    RSpec.expect { publisher.delete }.to RSpec.change(-> { Publisher.all.size }).by(-1)
  end

  it 'has many books' do
    penguin = Publisher.where(name: 'Penguin Books').first
    RSpec.expect(penguin.books.size).to RSpec.be_greater_than(0)
  end

  it 'groups publishers by country' do
    grouped = Publisher.dataset.group_and_count(:country)
    uk = grouped.detect { |g| g[:country] == 'UK' }
    RSpec.expect(uk[:count]).to RSpec.eq(1)
  end

  it 'orders publishers by founded year' do
    ordered = Publisher.dataset.order(:founded_year).map { |p| p[:name] }
    RSpec.expect(ordered.first).to RSpec.eq('Penguin Books')
  end
end
