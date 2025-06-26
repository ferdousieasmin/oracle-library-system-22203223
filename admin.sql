/******************************************************************************************
*  🚀 ADMIN & QUERY OPTIMIZATION SCRIPT                                                   *
*  📚 IUBAT University Library Management System                                           *
******************************************************************************************/

-- 1️⃣ CREATE INDEXES ON COMMONLY FILTERED COLUMNS
-- 🔍 Improves performance for search-heavy operations and join conditions

CREATE INDEX idx_books_author         ON BOOKS(author);           -- Speeds up filtering by author name
CREATE INDEX idx_books_title          ON BOOKS(title);            -- Enhances title-based lookups
CREATE INDEX idx_transactions_member  ON TRANSACTIONS(member_id); -- Optimizes member-related queries
CREATE INDEX idx_transactions_book    ON TRANSACTIONS(book_id);   -- Improves access to book transactions

-- 2️⃣ GENERATE EXECUTION PLAN FOR SPECIFIC QUERY
-- 🛠️  Useful for evaluating how Oracle processes the SQL internally

EXPLAIN PLAN FOR
SELECT * FROM BOOKS WHERE author = 'A.K. Rahman';

-- 📊 Use this to inspect the query plan:
-- SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

/******************************************************************************************
*  ✅ Tips for Efficient Database Tuning:
*    - Audit indexes regularly and remove redundant ones
*    - Review execution plans before adjusting slow queries
*    - Rebuild or reorganize indexes for large data sets to prevent fragmentation
******************************************************************************************/

-- 🏁 SCRIPT COMPLETE 🏁





