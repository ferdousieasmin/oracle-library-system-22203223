/******************************************************************************************
*  🏗️ DATABASE SETUP: SCHEMA & SAMPLE DATA                                               *
*  📚 IUBAT University Library Management System                                          *
******************************************************************************************/

-- 🔄 Drop and Create Database
DROP DATABASE IF EXISTS Library_Management_System;
CREATE DATABASE Library_Management_System;
USE Library_Management_System;

-- ===========================
-- 1️⃣ BOOKS TABLE
-- ===========================
CREATE TABLE BOOKS (
    book_id INT PRIMARY KEY,
    title VARCHAR(50) NOT NULL,
    author VARCHAR(50),
    publisher VARCHAR(50),
    publication_year DATE NOT NULL,
    isbn VARCHAR(25) UNIQUE,
    category VARCHAR(25),
    total_copies INT,
    available_copies INT,
    price DECIMAL(6,2)
);

-- ===========================
-- 2️⃣ MEMBERS TABLE
-- ===========================
CREATE TABLE MEMBERS (
    member_id INT PRIMARY KEY,
    first_name VARCHAR(25),
    last_name VARCHAR(25),
    email VARCHAR(50) UNIQUE,
    phone VARCHAR(25),
    address VARCHAR(100),
    membership_date DATE,
    membership_type VARCHAR(15)
);

-- ===========================
-- 3️⃣ TRANSACTIONS TABLE
-- ===========================
CREATE TABLE TRANSACTIONS (
    transaction_id INT PRIMARY KEY,
    member_id INT,
    book_id INT,
    issue_date DATE,
    due_date DATE,
    return_date DATE,
    fine_amount DECIMAL(6,2),
    status VARCHAR(15),
    FOREIGN KEY (member_id) REFERENCES MEMBERS(member_id),
    FOREIGN KEY (book_id) REFERENCES BOOKS(book_id)
);

-- ===========================
-- 4️⃣ SAMPLE DATA: BOOKS
-- ===========================
INSERT INTO BOOKS VALUES 
-- (book_id, title, author, publisher, publication_year, isbn, category, total, available, price)
(1, 'Data Science 101', 'John Smith', 'TechPub', '2020-01-01', 'ISBN001', 'Technology', 5, 3, 49.99),
(2, 'The Great Gatsby', 'F. Scott', 'Scribner', '1925-04-10', 'ISBN002', 'Fiction', 3, 2, 19.99),
-- [..truncated..]
(20, 'World History', 'Howard Zinn', 'HistPress', '1998-03-05', 'ISBN020', 'History', 5, 3, 35.00);

-- ===========================
-- 5️⃣ SAMPLE DATA: MEMBERS
-- ===========================
INSERT INTO MEMBERS VALUES
-- (member_id, first_name, last_name, email, phone, address, membership_date, type)
(1, 'Alice', 'Johnson', 'alice@example.com', '01234567891', 'Dhaka, BD', '2022-01-01', 'Student'),
(2, 'Bob', 'Smith', 'bob@example.com', '01234567892', 'Chittagong, BD', '2022-02-01', 'Faculty'),
-- [..truncated..]
(15, 'Omar', 'Ali', 'omar@example.com', '01234567905', 'Dhaka, BD', '2023-03-01', 'Staff');

-- ===========================
-- 6️⃣ SAMPLE DATA: TRANSACTIONS
-- ===========================
INSERT INTO TRANSACTIONS VALUES
-- (transaction_id, member_id, book_id, issue_date, due_date, return_date, fine_amount, status)
(1, 1, 1, '2025-06-01', '2025-06-10', '2025-06-09', 0.00, 'Returned'),
(2, 2, 2, '2025-06-03', '2025-06-13', NULL, 0.00, 'Pending'),
-- [..truncated..]
(25, 10, 5, '2025-06-11', '2025-06-21', NULL, 0.00, 'Pending');

-- ===========================
-- ✅ END OF FILE
-- ===========================






