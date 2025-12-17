require_relative '../spec_helper'

RSpec.describe 'Author model' do
  it 'loads seeded authors' do
    RSpec.expect(Author.all.size).to RSpec.eq(3)
  end

  it 'saves a valid author' do
    author = Author.new(name: 'Toni Morrison', country: 'USA', birth_year: 1931, biography: 'Pulitzer Prize winning novelist.')
    RSpec.expect(author.valid?).to RSpec.eq(true)
    author.save
    RSpec.expect(Author.all.map(&:name).include?('Toni Morrison')).to RSpec.be_truthy
  end

  it 'validates presence of name' do
    author = Author.new(country: 'USA', birth_year: 1950, biography: 'Test bio')
    RSpec.expect(author.valid?).to RSpec.eq(false)
    RSpec.expect(author.errors[:name].any?).to RSpec.be_truthy
  end

  it 'validates unique name' do
    author = Author.new(name: 'Harper Lee', country: 'USA', birth_year: 1950, biography: 'Bio content')
    RSpec.expect(author.valid?).to RSpec.eq(false)
    RSpec.expect(author.errors[:name].any?).to RSpec.be_truthy
  end

  it 'validates biography length' do
    author = Author.new(name: 'Short Bio', country: 'USA', birth_year: 1950, biography: 'Tiny')
    RSpec.expect(author.valid?).to RSpec.eq(false)
    RSpec.expect(author.errors[:biography].any?).to RSpec.be_truthy
  end

  it 'validates numeric birth year' do
    author = Author.new(name: 'Future Writer', country: 'USA', birth_year: 1500, biography: 'Long enough biography')
    RSpec.expect(author.valid?).to RSpec.eq(false)
    RSpec.expect(author.errors[:birth_year].any?).to RSpec.be_truthy
  end

  it 'returns associated books' do
    harper = Author.where(name: 'Harper Lee').first
    RSpec.expect(harper.books.first.title).to RSpec.eq('To Kill a Mockingbird')
  end

  it 'updates biography' do
    author = Author.where(name: 'George Orwell').first
    author.update(biography: 'British essayist and novelist renowned for social commentary.')
    RSpec.expect(Author.where(name: 'George Orwell').first.biography).to RSpec.eq('British essayist and novelist renowned for social commentary.')
  end

  it 'deletes an author' do
    author = Author.create(name: 'Temp Author', country: 'USA', birth_year: 1950, biography: 'Temporary biography entry')
    RSpec.expect { author.delete }.to RSpec.change(-> { Author.all.size }).by(-1)
  end

  it 'groups authors by country' do
    grouped = Author.dataset.group_and_count(:country)
    usa_group = grouped.detect { |g| g[:country] == 'USA' }
    RSpec.expect(usa_group[:count]).to RSpec.be_greater_than(0)
  end
end
