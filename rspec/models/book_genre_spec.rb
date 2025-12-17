require_relative '../spec_helper'

RSpec.describe 'BookGenre model' do
  it 'counts seed rows' do
    RSpec.expect(BookGenre.all.size).to RSpec.eq(5)
  end

  it 'requires book_id' do
    record = BookGenre.new(genre_id: 1)
    RSpec.expect(record.valid?).to RSpec.eq(false)
  end

  it 'requires genre_id' do
    record = BookGenre.new(book_id: 1)
    RSpec.expect(record.valid?).to RSpec.eq(false)
  end

  it 'creates a new link' do
    link = BookGenre.create(book_id: 1, genre_id: 2)
    RSpec.expect(BookGenre.where(id: link.id).first.book_id).to RSpec.eq(1)
  end

  it 'prevents missing associations' do
    record = BookGenre.new(book_id: nil, genre_id: nil)
    RSpec.expect(record.valid?).to RSpec.eq(false)
  end

  it 'fetches related book' do
    link = BookGenre.where(book_id: 2, genre_id: 2).first
    RSpec.expect(link.book.title).to RSpec.eq('1984')
  end

  it 'fetches related genre' do
    link = BookGenre.where(book_id: 2, genre_id: 2).first
    RSpec.expect(link.genre.name).to RSpec.eq('Dystopian')
  end

  it 'updates genre association' do
    link = BookGenre.create(book_id: 1, genre_id: 3)
    link.update(genre_id: 1)
    RSpec.expect(BookGenre.where(id: link.id).first.genre_id).to RSpec.eq(1)
  end

  it 'deletes link' do
    link = BookGenre.create(book_id: 3, genre_id: 2)
    RSpec.expect { link.delete }.to RSpec.change(-> { BookGenre.all.size }).by(-1)
  end

  it 'counts links per book' do
    counts = BookGenre.dataset.group_and_count(:book_id)
    for_book_two = counts.detect { |row| row[:book_id] == 2 }
    RSpec.expect(for_book_two[:count]).to RSpec.eq(2)
  end
end
