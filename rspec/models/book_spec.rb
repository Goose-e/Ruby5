require_relative '../spec_helper'

RSpec.describe 'Book model' do
  it 'counts seeded books' do
    RSpec.expect(Book.all.size).to RSpec.eq(3)
  end

  it 'validates presence of title' do
    book = Book.new(price: 1, publication_date: '2025-01-01', isbn: 'x', page_count: 10, author_id: 1, publisher_id: 1)
    RSpec.expect(book.valid?).to RSpec.eq(false)
    RSpec.expect(book.errors[:title].any?).to RSpec.be_truthy
  end

  it 'validates unique isbn' do
    book = Book.new(title: 'Duplicate', price: 1, publication_date: '2025-01-01', isbn: '9780451524935', page_count: 50, author_id: 1, publisher_id: 1)
    RSpec.expect(book.valid?).to RSpec.eq(false)
  end

  it 'validates page count minimum' do
    book = Book.new(title: 'Zero Pages', price: 1, publication_date: '2025-01-01', isbn: '123', page_count: 0, author_id: 1, publisher_id: 1)
    RSpec.expect(book.valid?).to RSpec.eq(false)
    RSpec.expect(book.errors[:page_count].any?).to RSpec.be_truthy
  end

  it 'creates a new book' do
    book = Book.create(title: 'New Release', price: 15.0, publication_date: '2025-02-02', isbn: '1111111111', page_count: 250, author_id: 1, publisher_id: 1)
    RSpec.expect(Book.where(isbn: '1111111111').first.title).to RSpec.eq('New Release')
  end

  it 'updates price' do
    book = Book.where(title: '1984').first
    book.update(price: 12.0)
    RSpec.expect(Book.where(title: '1984').first.price).to RSpec.eq(12.0)
  end

  it 'deletes a book' do
    book = Book.create(title: 'To Delete', price: 5.0, publication_date: '2024-01-01', isbn: 'DELETEISBN', page_count: 120, author_id: 1, publisher_id: 1)
    RSpec.expect { book.delete }.to RSpec.change(-> { Book.all.size }).by(-1)
  end

  it 'associates to author' do
    book = Book.where(title: '1984').first
    RSpec.expect(book.author.name).to RSpec.eq('George Orwell')
  end

  it 'associates to publisher' do
    book = Book.where(title: '1984').first
    RSpec.expect(book.publisher.name).to RSpec.eq('Penguin Books')
  end

  it 'fetches genres' do
    book = Book.where(title: '1984').first
    RSpec.expect(book.genres.map(&:name).sort).to RSpec.eq(['Classics', 'Dystopian'])
  end
end
