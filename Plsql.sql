/******************************************************************************************
*  🛠️ PL/SQL DEVELOPMENT: PROCEDURES, FUNCTIONS, TRIGGERS, ACCESS CONTROL                *
*  📚 IUBAT University Library Management System                                          *
******************************************************************************************/

-- 4.0: Member Activity Analytics
-- Displays each member's last issue date using LAG for historical trend tracking
SELECT 
    member_id,
    transaction_id,
    issue_date,
    LAG(issue_date) OVER (PARTITION BY member_id ORDER BY issue_date) AS previous_issue_date
FROM TRANSACTIONS
ORDER BY member_id, issue_date;

------------------------------------------------------------------------------------------
-- 4.1: Stored Procedure - ISSUE_BOOK
------------------------------------------------------------------------------------------

DELIMITER $$

CREATE PROCEDURE ISSUE_BOOK (
    IN p_member_id INT,
    IN p_book_id INT
)
proc_label: BEGIN
    DECLARE v_available INT DEFAULT 0;
    DECLARE v_max_transaction_id INT DEFAULT 0;

    -- Catch any SQL-level errors and rollback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT '❌ Failed to issue the book due to a system error.' AS message;
    END;

    START TRANSACTION;

    -- Lock and check if the book is available
    SELECT available_copies INTO v_available
    FROM BOOKS
    WHERE book_id = p_book_id
    FOR UPDATE;

    IF v_available IS NULL THEN
        ROLLBACK;
        SELECT '⚠️ Error: Book ID not found.' AS message;
        LEAVE proc_label;
    END IF;

    IF v_available <= 0 THEN
        ROLLBACK;
        SELECT '⚠️ Error: No available copies for this book.' AS message;
        LEAVE proc_label;
    END IF;

    -- Create a new transaction entry
    SELECT IFNULL(MAX(transaction_id), 0) INTO v_max_transaction_id FROM TRANSACTIONS;

    INSERT INTO TRANSACTIONS (
        transaction_id, member_id, book_id, issue_date, due_date, return_date, fine_amount, status
    ) VALUES (
        v_max_transaction_id + 1,
        p_member_id,
        p_book_id,
        CURDATE(),
        DATE_ADD(CURDATE(), INTERVAL 14 DAY),
        NULL,
        0.00,
        'Pending'
    );

    -- Decrease the number of available copies
    UPDATE BOOKS
    SET available_copies = available_copies - 1
    WHERE book_id = p_book_id;

    COMMIT;

    SELECT CONCAT('✅ Book issued successfully. Transaction No: ', v_max_transaction_id + 1) AS message;

END proc_label $$
DELIMITER ;

------------------------------------------------------------------------------------------
-- 4.2: Function - CALCULATE_FINE
------------------------------------------------------------------------------------------

DELIMITER $$

CREATE FUNCTION CALCULATE_FINE(p_transaction_id INT) 
RETURNS DECIMAL(6,2)
DETERMINISTIC
BEGIN
    DECLARE v_due_date DATE;
    DECLARE v_return_date DATE;
    DECLARE v_today DATE;
    DECLARE v_overdue_days INT DEFAULT 0;
    DECLARE v_fine DECIMAL(6,2) DEFAULT 0.00;

    SET v_today = CURDATE();

    -- Fetch transaction's due and return dates
    SELECT due_date, return_date 
    INTO v_due_date, v_return_date
    FROM TRANSACTIONS
    WHERE transaction_id = p_transaction_id;

    -- Calculate delay duration
    IF v_return_date IS NOT NULL THEN
        SET v_overdue_days = DATEDIFF(v_return_date, v_due_date);
    ELSE
        SET v_overdue_days = DATEDIFF(v_today, v_due_date);
    END IF;

    -- Charge BDT 5 per day if overdue
    IF v_overdue_days > 0 THEN
        SET v_fine = v_overdue_days * 5;
    ELSE
        SET v_fine = 0.00;
    END IF;

    RETURN v_fine;
END $$
DELIMITER ;

-- 🔍 Sample call:
-- SELECT CALCULATE_FINE(102) AS fine_amount;

------------------------------------------------------------------------------------------
-- 4.3: Trigger - Auto-increment Available Copies on Return
------------------------------------------------------------------------------------------

DELIMITER $$

CREATE TRIGGER trg_increment_copies_on_return
AFTER UPDATE ON TRANSACTIONS
FOR EACH ROW
BEGIN
    -- Increase available copies only if book is marked 'Returned'
    IF OLD.status <> 'Returned' AND NEW.status = 'Returned' THEN
        UPDATE BOOKS
        SET available_copies = available_copies + 1
        WHERE book_id = NEW.book_id;
    END IF;
END $$
DELIMITER ;

------------------------------------------------------------------------------------------
-- 4.4: User Roles and Privileges
------------------------------------------------------------------------------------------

-- Create database users with appropriate access rights
CREATE USER IF NOT EXISTS 'lib_staff'@'localhost' IDENTIFIED BY 'staff_secure123';
CREATE USER IF NOT EXISTS 'reader_user'@'localhost' IDENTIFIED BY 'reader_pass456';

-- Full permissions for library staff
GRANT ALL PRIVILEGES ON Library_Management_System.* TO 'lib_staff'@'localhost';

-- Read-only access for student readers
GRANT SELECT ON Library_Management_System.BOOKS TO 'reader_user'@'localhost';

-- Refresh grant settings
FLUSH PRIVILEGES;

-- 🧹 Cleanup commands (optional)
-- DROP USER IF EXISTS 'lib_staff'@'localhost';
-- DROP USER IF EXISTS 'reader_user'@'localhost';

------------------------------------------------------------------------------------------
-- ✅ SCRIPT EXECUTION COMPLETE











