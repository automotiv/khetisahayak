books = []

def get_all_books():
    return books

def insert_book(name, author, pages=None, publisher=None):
    books.append({
        'name': name, 
        'author': author, 
        'pages': pages,
        'publisher': publisher,
        'read': False
    })

def mark_book_as_read(name):
    for book in books:
        if book['name'].lower() == name.lower():
            book['read'] = True
            return True
    return False

def delete_book(name):
    global books
    books = [book for book in books if book['name'].lower() != name.lower()]

def search_books(query):
    """
    Search for books by name, author, or publisher (case-insensitive)
    Returns a list of matching books
    """
    query = query.lower()
    matching_books = []
    
    for book in books:
        if (query in book['name'].lower() or 
            query in book['author'].lower() or
            (book.get('publisher') and query in book['publisher'].lower())):
            matching_books.append(book)
    
    return matching_books

def update_book(old_name, new_name=None, new_author=None, new_pages=None, new_publisher=None):
    """
    Update book details. If any parameter is None, keep the old value
    Returns True if book was found and updated, False otherwise
    """
    for book in books:
        if book['name'].lower() == old_name.lower():
            if new_name is not None:
                book['name'] = new_name
            if new_author is not None:
                book['author'] = new_author
            if new_pages is not None:
                book['pages'] = new_pages
            if new_publisher is not None:
                book['publisher'] = new_publisher
            return True
    return False

def get_book_by_name(name):
    """
    Get a specific book by name (case-insensitive)
    Returns the book dictionary or None if not found
    """
    for book in books:
        if book['name'].lower() == name.lower():
            return book
    return None

# def delete_book(name):
#     for book in books:
#         if book['name'] == name:
#             books.remove(book)

