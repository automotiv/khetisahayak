import os
import sqlite3


def get_database_path():
    return os.path.join(os.path.dirname(os.path.dirname(__file__)), "employees.db")


def create_employees_table(database_path: str) -> None:
    connection = sqlite3.connect(database_path)
    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS employees (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                first_name TEXT NOT NULL,
                last_name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                hire_date TEXT NOT NULL
            );
            """
        )
        connection.commit()
    finally:
        connection.close()


def main() -> None:
    db_path = get_database_path()
    create_employees_table(db_path)
    print(f"SQLite database initialized at: {db_path}")
    print("Table 'employees' (5 columns) is ready.")


if __name__ == "__main__":
    main()



