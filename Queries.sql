/******************************************************************************************
*  📊 ADVANCED SQL ANALYTICS & DATA MANAGEMENT                                            *
*  📚 IUBAT University Library Management System                                           *
******************************************************************************************/

-- ===========================
-- 2.1 DATA RETRIEVAL QUERIES
-- ===========================

-- 1️⃣ Retrieve books that have been partially borrowed
SELECT book_id, title, total_copies, available_copies
FROM BOOKS
WHERE available_copies < total_copies;

-- 2️⃣ Identify users with overdue borrowed books
SELECT M.member_id, M.first_name, M.last_name, T.book_id, T.due_date
FROM MEMBERS M
JOIN TRANSACTIONS T ON M.member_id = T.member_id
WHERE T.due_date < CURDATE() AND T.status = 'Overdue';

-- 3️⃣ Fetch top 5 most frequently issued books
SELECT B.book_id, B.title, COUNT(T.transaction_id) AS borrow_count
FROM BOOKS B
JOIN TRANSACTIONS T ON B.book_id = T.book_id
GROUP BY B.book_id, B.title
ORDER BY borrow_count DESC
LIMIT 5;

-- 4️⃣ Show members who consistently return books late
SELECT DISTINCT M.member_id, M.first_name, M.last_name
FROM MEMBERS M
JOIN TRANSACTIONS T ON M.member_id = T.member_id
WHERE T.return_date > T.due_date;

-- ===========================
-- 2.2 DATA MANIPULATION TASKS
-- ===========================

-- 1️⃣ Apply ₹5 per day fine to all late return transactions
SET SQL_SAFE_UPDATES = 0;
UPDATE TRANSACTIONS
SET fine_amount = DATEDIFF(return_date, due_date) * 5
WHERE return_date > due_date;

-- 2️⃣ Add a new member, preventing duplicate email or phone entry
INSERT INTO MEMBERS (member_id, first_name, last_name, email, phone, address, membership_date, membership_type)
SELECT 21, 'Nazia', 'Khan', 'nazia.khan@example.com', '01876543210', 'Barisal, BD', CURDATE(), 'Alumni'
WHERE NOT EXISTS (
    SELECT 1 FROM MEMBERS WHERE email = 'nazia.khan@example.com' OR phone = '01876543210'
);

-- 3️⃣ Move completed and old transactions to an archive

-- Step A: Create archive table structure if it doesn't exist
CREATE TABLE IF NOT EXISTS TRANSACTION_ARCHIVE AS
SELECT * FROM TRANSACTIONS WHERE 1 = 0;

-- Step B: Copy old returned records to archive
INSERT INTO TRANSACTION_ARCHIVE
SELECT * FROM TRANSACTIONS
WHERE status = 'Returned' AND return_date < CURDATE() - INTERVAL 2 YEAR;

-- Step C: Remove archived entries from active table
DELETE FROM TRANSACTIONS
WHERE status = 'Returned' AND return_date < CURDATE() - INTERVAL 2 YEAR;

-- 4️⃣ Categorize books by publication era
UPDATE BOOKS
SET category = CASE
    WHEN YEAR(publication_year) < 2000 THEN 'Vintage'
    WHEN YEAR(publication_year) BETWEEN 2000 AND 2010 THEN 'Regular'
    ELSE 'Recent'
END;

-- ===========================
-- 2.3 JOIN OPERATIONS
-- ===========================

-- 1️⃣ View full transaction history with member and book details (for overdue only)
SELECT 
    T.transaction_id,
    M.member_id, M.first_name, M.last_name,
    B.book_id, B.title, B.category,
    T.issue_date, T.due_date, T.return_date, T.status
FROM TRANSACTIONS T
INNER JOIN MEMBERS M ON T.member_id = M.member_id
INNER JOIN BOOKS B ON T.book_id = B.book_id
WHERE T.status = 'Overdue';

-- 2️⃣ Count transactions for each book, include books with zero transactions
SELECT 
    B.book_id, B.title, COUNT(T.transaction_id) AS transaction_count
FROM BOOKS B
LEFT JOIN TRANSACTIONS T ON B.book_id = T.book_id
GROUP BY B.book_id, B.title
ORDER BY transaction_count DESC;

-- 3️⃣ Match members who have read books from the same genre
SELECT DISTINCT 
    M1.member_id AS reader_1, M1.first_name AS name_1,
    M2.member_id AS reader_2, M2.first_name AS name_2,
    B1.category
FROM TRANSACTIONS T1
JOIN MEMBERS M1 ON T1.member_id = M1.member_id
JOIN BOOKS B1 ON T1.book_id = B1.book_id
JOIN TRANSACTIONS T2 ON B1.category = (
    SELECT B2.category FROM BOOKS B2 WHERE B2.book_id = T2.book_id
)
JOIN MEMBERS M2 ON T2.member_id = M2.member_id
WHERE M1.member_id <> M2.member_id;

-- 4️⃣ Generate all valid member-book pairs (sample for recommendations)
SELECT 
    M.member_id, M.first_name, M.last_name,
    B.book_id, B.title, B.category
FROM MEMBERS M
CROSS JOIN BOOKS B
LIMIT 50;

-- ===========================
-- 3.2 SUBQUERIES & COMPLEX FILTERS
-- ===========================

-- 1️⃣ Find books issued more than the system-wide average
SELECT book_id, title
FROM BOOKS
WHERE book_id IN (
    SELECT book_id
    FROM TRANSACTIONS
    GROUP BY book_id
    HAVING COUNT(*) > (
        SELECT AVG(issue_count)
        FROM (
            SELECT COUNT(*) AS issue_count
            FROM TRANSACTIONS
            GROUP BY book_id
        ) AS issue_summary
    )
);

-- 2️⃣ Identify members whose total fine exceeds the average for their category
SELECT member_id, first_name, last_name, total_fine
FROM (
    SELECT M.member_id, M.first_name, M.last_name, M.membership_type,
           SUM(T.fine_amount) AS total_fine
    FROM MEMBERS M
    JOIN TRANSACTIONS T ON M.member_id = T.member_id
    GROUP BY M.member_id, M.first_name, M.last_name, M.membership_type
) AS fines_summary
WHERE total_fine > (
    SELECT AVG(total_fine)
    FROM (
        SELECT M.member_id, M.membership_type, SUM(T.fine_amount) AS total_fine
        FROM MEMBERS M
        JOIN TRANSACTIONS T ON M.member_id = T.member_id
        GROUP BY M.member_id, M.membership_type
    ) AS avg_fines
    WHERE avg_fines.membership_type = fines_summary.membership_type
);

-- 3️⃣ Find currently available books in the most popular genre
SELECT book_id, title, category
FROM BOOKS
WHERE available_copies > 0
AND category = (
    SELECT B.category
    FROM BOOKS B
    JOIN TRANSACTIONS T ON B.book_id = T.book_id
    GROUP BY B.category
    ORDER BY COUNT(*) DESC
    LIMIT 1
);

-- 4️⃣ Return the second most active member by total borrowings
SELECT member_id, first_name, last_name, txn_count
FROM (
    SELECT M.member_id, M.first_name, M.last_name, COUNT(T.transaction_id) AS txn_count
    FROM MEMBERS M
    JOIN TRANSACTIONS T ON M.member_id = T.member_id
    GROUP BY M.member_id, M.first_name, M.last_name
) AS txn_stats
WHERE txn_count = (
    SELECT MAX(count_val) FROM (
        SELECT COUNT(transaction_id) AS count_val
        FROM TRANSACTIONS
        GROUP BY member_id
        HAVING COUNT(transaction_id) < (
            SELECT MAX(highest_count) FROM (
                SELECT COUNT(transaction_id) AS highest_count
                FROM TRANSACTIONS
                GROUP BY member_id
            ) AS max_txn
        )
    ) AS second_top
);

-- ===========================
-- 3.3 AGGREGATION & WINDOW LOGIC
-- ===========================

-- 1️⃣ Monthly fine trend with cumulative totals
SELECT 
    DATE_FORMAT(return_date, '%Y-%m') AS month,
    SUM(fine_amount) AS total_fine_this_month,
    SUM(SUM(fine_amount)) OVER (ORDER BY DATE_FORMAT(return_date, '%Y-%m')) AS cumulative_fine
FROM TRANSACTIONS
WHERE fine_amount > 0
GROUP BY month
ORDER BY month;

-- 2️⃣ Assign borrow ranking within each membership type
SELECT 
    member_id, first_name, last_name, membership_type, borrow_count,
    RANK() OVER (PARTITION BY membership_type ORDER BY borrow_count DESC) AS type_rank
FROM (
    SELECT M.member_id, M.first_name, M.last_name, M.membership_type, COUNT(T.transaction_id) AS borrow_count
    FROM MEMBERS M
    LEFT JOIN TRANSACTIONS T ON M.member_id = T.member_id
    GROUP BY M.member_id, M.first_name, M.last_name, M.membership_type
) AS borrowing_activity;

-- 3️⃣ Category-wise contribution to total transactions
SELECT 
    B.category,
    COUNT(T.transaction_id) AS transactions_in_category,
    ROUND(100 * COUNT(T.transaction_id) / (SELECT COUNT(*) FROM TRANSACTIONS), 2) AS category_percentage
FROM BOOKS B
LEFT JOIN TRANSACTIONS T ON B.book_id = T.book_id
GROUP BY B.category
ORDER BY category_percentage DESC;

-- ===========================
-- ✅ END OF SCRIPT
-- ===========================



