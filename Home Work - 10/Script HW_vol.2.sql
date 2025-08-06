-- создание базы
create database ExpenseAnalysis

SET XACT_ABORT ON

-- создание таблиц
use ExpenseAnalysis

CREATE TABLE [Transactions] (
    [transaction_id] int  NOT NULL ,
    [amount] decimal(6,2)  NOT NULL ,
    [date] datetime2  NOT NULL ,
    [description] nvarchar(max)  NOT NULL ,
    [expense_type_id] int  NOT NULL ,
    [operation_type_id] int  NOT NULL ,
    [tax_type_id] int  NOT NULL ,
    [category_id] int  NOT NULL ,
    [transactionstag_id] int  NOT NULL ,
    CONSTRAINT [PK_Transactions] PRIMARY KEY CLUSTERED (
        [transaction_id] ASC
    )
)

CREATE TABLE [ExpenseType] (
    -- Clustered
    [expense_type_id] int  NOT NULL ,
    [name] nvarchar(12)  NOT NULL ,
    CONSTRAINT [PK_ExpenseType] PRIMARY KEY CLUSTERED (
        [expense_type_id] ASC
    )
)

CREATE TABLE [OperationTypes] (
    -- Clustered
    [operation_type_id] int  NOT NULL ,
    [name] nvarchar(6)  NOT NULL ,
    CONSTRAINT [PK_OperationTypes] PRIMARY KEY CLUSTERED (
        [operation_type_id] ASC
    )
)

CREATE TABLE [TaxTypes] (
    -- Clustered
    [tax_type_id] int  NOT NULL ,
    [name] nvarchar(15)  NOT NULL ,
	[rate] decimal(2,0) NOT NULL,
    CONSTRAINT [PK_TaxTypes] PRIMARY KEY CLUSTERED (
        [tax_type_id] ASC
    )
)

CREATE TABLE [Categories] (
    -- Clustered
    [category_id] int  NOT NULL ,
    [name] nvarchar(11)  NOT NULL ,
    CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED (
        [category_id] ASC
    )
)

CREATE TABLE [TransactionsTags] (
    [transaction_id] int  NOT NULL ,
    [tag_id] int  NOT NULL 
)

CREATE TABLE [Tags] (
    -- Clustered
    [tag_id] int  NOT NULL ,
    [name] nvarchar(12)  NOT NULL ,
    CONSTRAINT [PK_Tags] PRIMARY KEY CLUSTERED (
        [tag_id] ASC
    )
)

ALTER TABLE [Transactions] WITH CHECK ADD CONSTRAINT [FK_Transactions_operation_type_id] FOREIGN KEY([operation_type_id])
REFERENCES [OperationTypes] ([operation_type_id])

ALTER TABLE [Transactions] CHECK CONSTRAINT [FK_Transactions_operation_type_id]

ALTER TABLE [Transactions] WITH CHECK ADD CONSTRAINT [FK_Transactions_tax_type_id] FOREIGN KEY([tax_type_id])
REFERENCES [TaxTypes] ([tax_type_id])

ALTER TABLE [Transactions] CHECK CONSTRAINT [FK_Transactions_tax_type_id]

ALTER TABLE [Transactions] WITH CHECK ADD CONSTRAINT [FK_Transactions_category_id] FOREIGN KEY([category_id])
REFERENCES [Categories] ([category_id])

ALTER TABLE [Transactions] CHECK CONSTRAINT [FK_Transactions_category_id]

ALTER TABLE [Transactions] WITH CHECK ADD CONSTRAINT [FK_Transactions_transactionstag_id] FOREIGN KEY([transactionstag_id])
REFERENCES [Tags] ([tag_id])

ALTER TABLE [Transactions] CHECK CONSTRAINT [FK_Transactions_transactionstag_id]

ALTER TABLE [Transactions] WITH CHECK ADD CONSTRAINT [FK_Transactions_expense_type_id] FOREIGN KEY([expense_type_id])
REFERENCES [ExpenseType] ([expense_type_id])

ALTER TABLE [Transactions] CHECK CONSTRAINT [FK_Transactions_expense_type_id]

ALTER TABLE [TransactionsTags] WITH CHECK ADD CONSTRAINT [FK_TransactionsTags_transaction_id] FOREIGN KEY([transaction_id])
REFERENCES [Transactions] ([transaction_id])

ALTER TABLE [TransactionsTags] CHECK CONSTRAINT [FK_TransactionsTags_transaction_id]

ALTER TABLE [TransactionsTags] WITH CHECK ADD CONSTRAINT [FK_TransactionsTags_tag_id] FOREIGN KEY([tag_id])
REFERENCES [Tags] ([tag_id])

ALTER TABLE [TransactionsTags] CHECK CONSTRAINT [FK_TransactionsTags_tag_id]

-- создание индексов
CREATE NONCLUSTERED INDEX IX_Transactions_Date_Operation
ON Transactions (date, operation_type_id);

CREATE NONCLUSTERED INDEX IX_Transaction_Tags_Tag
ON TransactionsTags (tag_id);

CREATE NONCLUSTERED INDEX IX_Tags
ON Tags (tag_id);

CREATE NONCLUSTERED INDEX IX_Categories
ON Categories (category_id);

CREATE NONCLUSTERED INDEX IX_Operation_Types
ON OperationTypes (operation_type_id);

CREATE NONCLUSTERED INDEX IX_Expense_Types
ON ExpenseType (expense_type_id);

CREATE NONCLUSTERED INDEX IX_Tax_Types
ON TaxTypes (tax_type_id);

CREATE UNIQUE CLUSTERED INDEX [IX_TransactionsTags_Unique]
ON [TransactionsTags] ([transaction_id], [tag_id])

-- ограничения
-- 1. Сумма операции не может быть нулевой
ALTER TABLE Transactions
ADD CONSTRAINT CHK_Transactions_Amount_NonZero
CHECK (amount <> 0);

-- 2. Имя тега не может быть пустым
ALTER TABLE Tags
ADD CONSTRAINT CHK_Tags_Name_NotEmpty
CHECK (LEN(LTRIM(RTRIM(name))) > 0);

-- 3. Имя категории не может быть длиннее 50 символов
ALTER TABLE Categories
ADD CONSTRAINT CHK_Categories_Name_Length
CHECK (LEN(name) <= 50);

-- 4. Допустимые значения - Доход и Расход
ALTER TABLE OperationTypes
ADD CONSTRAINT CHK_Operation_Types_Name_Valid
CHECK (name IN (N'Доход', N'Расход'));

-- 5. Имя не должно содержать цифр
ALTER TABLE ExpenseType
ADD CONSTRAINT CHK_Expense_Type_NoDigits
CHECK (name NOT LIKE '%[0-9]%');

-- 6. Длина имени налога должна быть до 1000 символов, чтобы исключить мусор
ALTER TABLE TaxTypes
ADD CONSTRAINT CHK_Tax_Types_Name_Length
CHECK (LEN(name) <= 100);