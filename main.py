from utils import database

USER_CHOICE = """
Enter:
- 'a' to add a new book
- 'l' to list all books
- 'r' to mark a book as read
- 'd' to delete a book
- 's' to search for books
- 'u' to update a book
- 'q' to quit

Your choice: """


def menu():
   
    user_input = input(USER_CHOICE)
    while user_input != 'q':
        if user_input == 'a':
            prompt_add_book()
        elif user_input == 'l':
            list_books()
        elif user_input == 'r':
            prompt_read_book()
        elif user_input == 'd':
            prompt_delete_book()
        elif user_input == 's':
            prompt_search_books()
        elif user_input == 'u':
            prompt_update_book()
        else:
            print("Invalid choice. Please try again.")

        user_input = input(USER_CHOICE)


def prompt_add_book():
    name = input('Enter the new book name: ')
    author = input('Enter the new book author: ')
    pages = input('Enter number of pages (optional): ').strip()
    publisher = input('Enter publisher (optional): ').strip()

    if name.strip() and author.strip():
        # Convert pages to integer if provided, otherwise None
        pages_int = None
        if pages:
            try:
                pages_int = int(pages)
            except ValueError:
                print("Warning: Invalid page number. Book added without page count.")
        
        # Use None for empty publisher
        publisher_val = publisher if publisher else None
        
        database.insert_book(name, author, pages_int, publisher_val)
        print(f"Book '{name}' by {author} added successfully!")
    else:
        print("Error: Book name and author cannot be empty.")


def list_books():
    books = database.get_all_books()
    if not books:
        print("No books found in your collection.")
        return
    
    print("\nYour Book Collection:")
    print("-" * 80)
    for book in books:
        read = 'YES' if book['read'] else 'NO'
        pages_info = f" ({book['pages']} pages)" if book.get('pages') else ""
        publisher_info = f" - {book['publisher']}" if book.get('publisher') else ""
        print(f"{book['name']} by {book['author']}{pages_info}{publisher_info} — Read: {read}")
    print("-" * 80)


def prompt_read_book():
    name = input('Enter the name of the book you just finished reading: ')
    
    if database.mark_book_as_read(name):
        print(f"Book '{name}' marked as read!")
    else:
        print(f"Book '{name}' not found in your collection.")


def prompt_delete_book():
    name = input('Enter the name of the book you wish to delete: ')
    
    # Check if book exists before deleting
    if database.get_book_by_name(name):
        database.delete_book(name)
        print(f"Book '{name}' deleted successfully!")
    else:
        print(f"Book '{name}' not found in your collection.")


def prompt_search_books():
    query = input('Enter search term (book name, author, or publisher): ')
    
    if not query.strip():
        print("Error: Search term cannot be empty.")
        return
    
    matching_books = database.search_books(query)
    
    if not matching_books:
        print(f"No books found matching '{query}'.")
        return
    
    print(f"\nSearch Results for '{query}':")
    print("-" * 80)
    for book in matching_books:
        read = 'YES' if book['read'] else 'NO'
        pages_info = f" ({book['pages']} pages)" if book.get('pages') else ""
        publisher_info = f" - {book['publisher']}" if book.get('publisher') else ""
        print(f"{book['name']} by {book['author']}{pages_info}{publisher_info} — Read: {read}")
    print("-" * 80)


def prompt_update_book():
    old_name = input('Enter the name of the book you want to update: ')
    
    # Check if book exists
    book = database.get_book_by_name(old_name)
    if not book:
        print(f"Book '{old_name}' not found in your collection.")
        return
    
    # Display current details
    pages_display = f" ({book['pages']} pages)" if book.get('pages') else ""
    publisher_display = f" - {book['publisher']}" if book.get('publisher') else ""
    print(f"\nCurrent details: {book['name']} by {book['author']}{pages_display}{publisher_display}")
    print("Enter new details (press Enter to keep current value):")
    
    new_name = input(f"New book name [{book['name']}]: ").strip()
    new_author = input(f"New author name [{book['author']}]: ").strip()
    new_pages = input(f"New page count [{book.get('pages', 'N/A')}]: ").strip()
    new_publisher = input(f"New publisher [{book.get('publisher', 'N/A')}]: ").strip()
    
    # Process input values
    if not new_name:
        new_name = None
    if not new_author:
        new_author = None
    
    # Process pages
    new_pages_int = None
    if new_pages and new_pages != 'N/A':
        try:
            new_pages_int = int(new_pages)
        except ValueError:
            print("Warning: Invalid page number. Page count not updated.")
    
    # Process publisher
    if not new_publisher or new_publisher == 'N/A':
        new_publisher = None
    
    if database.update_book(old_name, new_name, new_author, new_pages_int, new_publisher):
        print("Book updated successfully!")
    else:
        print("Error: Failed to update book.")


if __name__ == "__main__":
    menu()
