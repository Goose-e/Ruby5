require_relative '../spec_helper'

RSpec.describe 'Genre model' do
  it 'counts seeded genres' do
    RSpec.expect(Genre.all.size).to RSpec.eq(3)
  end

  it 'validates presence of name' do
    genre = Genre.new(description: 'No name provided')
    RSpec.expect(genre.valid?).to RSpec.eq(false)
    RSpec.expect(genre.errors[:name].any?).to RSpec.be_truthy
  end

  it 'requires description' do
    genre = Genre.new(name: 'Test')
    RSpec.expect(genre.valid?).to RSpec.eq(false)
    RSpec.expect(genre.errors[:description].any?).to RSpec.be_truthy
  end

  it 'validates description length' do
    genre = Genre.new(name: 'Test', description: 'Tiny')
    RSpec.expect(genre.valid?).to RSpec.eq(false)
  end

  it 'enforces unique name' do
    genre = Genre.new(name: 'Classics', description: 'Duplicate name')
    RSpec.expect(genre.valid?).to RSpec.eq(false)
  end

  it 'creates a new genre' do
    created = Genre.create(name: 'Mystery', description: 'Whodunit stories', shelf_code: 'MYS')
    RSpec.expect(created.id.nil?).to RSpec.eq(false)
  end

  it 'updates shelf code' do
    genre = Genre.where(name: 'Dystopian').first
    genre.update(shelf_code: 'DYP')
    RSpec.expect(Genre.where(name: 'Dystopian').first.shelf_code).to RSpec.eq('DYP')
  end

  it 'deletes a genre' do
    genre = Genre.create(name: 'Temporary Genre', description: 'Temp data')
    RSpec.expect { genre.delete }.to RSpec.change(-> { Genre.all.size }).by(-1)
  end

  it 'returns related book genres' do
    genre = Genre.where(name: 'Classics').first
    RSpec.expect(genre.book_genres.size).to RSpec.be_greater_than(0)
  end

  it 'groups genres by shelf code availability' do
    with_code = Genre.dataset.where { |row| !row[:shelf_code].nil? }
    RSpec.expect(with_code.count).to RSpec.be_greater_than(0)
  end
end
