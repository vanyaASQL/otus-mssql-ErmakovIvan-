/*
Берем таблицу Sales.Invoices так как: 
	- Это одна из самых больших таблиц в БД
	- Она отлично подходит для секционирования по дате (например, по году)
	- Имеет четкий временной критерий для распределения данных
*/

-- Анализ таблицы
SELECT 
    t.name AS TableName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB 
FROM 
    sys.tables t
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
    t.name = 'Invoices' AND SCHEMA_NAME(t.schema_id) = 'Sales'
GROUP BY 
    t.name, p.rows;

-- диапазон дат
SELECT 
    MIN(InvoiceDate) AS MinDate,
    MAX(InvoiceDate) AS MaxDate,
    COUNT(*) AS TotalRows
FROM Sales.Invoices;

-- Создаем файловые группы для секций (если нужно оптимизировать хранение)
ALTER DATABASE WideWorldImporters ADD FILEGROUP [FG_Invoices_2013];
ALTER DATABASE WideWorldImporters ADD FILEGROUP [FG_Invoices_2014];
ALTER DATABASE WideWorldImporters ADD FILEGROUP [FG_Invoices_2015];
ALTER DATABASE WideWorldImporters ADD FILEGROUP [FG_Invoices_2016];

-- Создаем функцию секционирования (по годам)
CREATE PARTITION FUNCTION pf_Invoices_ByYear (date)
AS RANGE RIGHT FOR VALUES (
	'2012-01-01'
	, '2013-01-01'
	, '2014-01-01'
    , '2015-01-01' 
    , '2016-01-01'
	, '2017-01-01'
	, '2018-01-01'
	, '2019-01-01'
	, '2020-01-01'
	, '2021-01-01'
);

-- Создаем схему секционирования
CREATE PARTITION SCHEME ps_Invoices_ByYear
AS PARTITION pf_Invoices_ByYear
ALL TO ([PRIMARY]);

-- Создаем новую таблицу с той же структурой, но на схеме секционирования
SELECT * INTO Sales.Invoices_Partitioned
FROM [Sales].[Invoices]

-- так как у меня не работает bulk insert на рабочем компьютере, я произвел секционирование через Свойства таблицы => Хранилище

-- cам скрипт выглядит так:
DECLARE 
	@path NVARCHAR(256) = N'd:\temp\',
	@FileName NVARCHAR(256) = N'InvoiceLines.txt',
	@onlyScript BIT = 0, 
	@query	NVARCHAR(MAX),
	@dbname NVARCHAR(255) = DB_NAME(),
	@batchsize INT = 1000;
	
BEGIN TRY
	IF @FileName IS NOT NULL
	BEGIN
		SET @query = 'BULK INSERT ['+@dbname+'].[Sales].[Invoices_Partitioned]
				FROM "' + @path + @FileName + '"
				WITH 
					(
					BATCHSIZE = '+CAST(@batchsize AS VARCHAR(255))+', 
					DATAFILETYPE = ''widechar'',
					FIELDTERMINATOR = ''@eu&$'',
					ROWTERMINATOR =''\n'',
					KEEPNULLS,
					TABLOCK        
					);'

		PRINT @query

		IF @onlyScript = 0
			EXEC sp_executesql @query 
		PRINT 'Bulk insert '+@FileName+' is done, current time '+CONVERT(VARCHAR, GETUTCDATE(),120);
	END;
END TRY

BEGIN CATCH
	SELECT   
		ERROR_NUMBER() AS ErrorNumber  
		,ERROR_MESSAGE() AS ErrorMessage; 

	PRINT 'ERROR in Bulk insert '+@FileName+' , current time '+CONVERT(VARCHAR, GETUTCDATE(),120);

END CATCH