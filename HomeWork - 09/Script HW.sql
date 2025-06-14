/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

-- 1. Вариант 1: OPENXML
declare @xmlDocument xml

select @xmlDocument = BulkColumn
from openrowset(bulk 'C:\Users\ermakov.im\Desktop\УЧЕБА В OTUS\ДЗ_9\StockItems-188-1fb5df.xml', single_clob) as t

declare @docHandle int;
exec sp_xml_preparedocument @docHandle output, @xmlDocument;

select * into #TableXML
from openxml(@docHandle, N'/StockItems/Item') --путь к строкам
with ( 
	  [StockItemName] nvarchar(max) '@Name'
	, [SupplierID] int 'SupplierID'
	, [UnitPackageID] int 'Package/UnitPackageID'
	, [OuterPackageID] int 'Package/OuterPackageID'
	, [QuantityPerOuter] int 'Package/QuantityPerOuter'
	, [TypicalWeightPerUnit] decimal(18,3) 'Package/TypicalWeightPerUnit'
	, [LeadTimeDays] int 'LeadTimeDays'
	, [IsChillerStock] bit 'IsChillerStock'
	, [TaxRate] decimal(18,3) 'TaxRate'
	, [UnitPrice] decimal(18,2) 'UnitPrice'
)

merge Warehouse.StockItems as Target
using #TableXML AS Source
    on (Target.[StockItemName] = Source.[StockItemName])
when matched
    then update 
        set [QuantityPerOuter] = Source.[QuantityPerOuter]
		, [TypicalWeightPerUnit] = Source.[TypicalWeightPerUnit]
		, [LeadTimeDays] = Source.[LeadTimeDays]
		, [IsChillerStock] = Source.[IsChillerStock]
		, [TaxRate] = Source.[TaxRate]
		, [UnitPrice] = Source.[UnitPrice]
when not matched 
    then insert (
		[StockItemName]
		, [SupplierID]
		, [UnitPackageID]
		, [OuterPackageID]
		, [QuantityPerOuter]
		, [TypicalWeightPerUnit]
		, [LeadTimeDays]
		, [IsChillerStock]
		, [TaxRate]
		, [UnitPrice]
		, [LastEditedBy])
        values (Source.[StockItemName]
			, Source.[SupplierID]
			, Source.[UnitPackageID]
			, Source.[OuterPackageID]
			, Source.[QuantityPerOuter]
			, Source.[TypicalWeightPerUnit]
			, Source.[LeadTimeDays]
			, Source.[IsChillerStock]
			, Source.[TaxRate]
			, Source.[UnitPrice]
			, 3);

--drop table #TableXML

-- 2. Вариант 2: XQuery
declare @x xml
set @x = (
		select *
		from openrowset(bulk 'C:\Users\ermakov.im\Desktop\УЧЕБА В OTUS\ДЗ_9\StockItems-188-1fb5df.xml', single_clob) as d
		)

select
	[StockItemName] = t.StockItemsXML.value('(@Name)[1]', 'nvarchar(max)')
	, [SupplierID] = t.StockItemsXML.value('(SupplierID)[1]', 'int')
	, [UnitPackageID] = t.StockItemsXML.value('(Package/UnitPackageID)[1]', 'int')
	, [OuterPackageID] = t.StockItemsXML.value('(Package/OuterPackageID)[1]', 'int')
	, [QuantityPerOuter] = t.StockItemsXML.value('(Package/QuantityPerOuter)[1]', 'int')
	, [TypicalWeightPerUnit] = t.StockItemsXML.value('(Package/TypicalWeightPerUnit)[1]', 'decimal(18,3)')
	, [LeadTimeDays] = t.StockItemsXML.value('(LeadTimeDays)[1]', 'int')
	, [IsChillerStock] = t.StockItemsXML.value('(IsChillerStock)[1]', 'bit')
	, [TaxRate] = t.StockItemsXML.value('(TaxRate)[1]', 'decimal(18,3)')
	, [UnitPrice] = t.StockItemsXML.value('(UnitPrice)[1]', 'decimal(18,2)')
	into #TableVar2XML
from @x.nodes('/StockItems/Item') as t(StockItemsXML)

merge Warehouse.StockItems as Target
using #TableVar2XML AS Source
    on (Target.[StockItemName] = Source.[StockItemName])
when matched 
    then update 
        set [QuantityPerOuter] = Source.[QuantityPerOuter]
		, [TypicalWeightPerUnit] = Source.[TypicalWeightPerUnit]
		, [LeadTimeDays] = Source.[LeadTimeDays]
		, [IsChillerStock] = Source.[IsChillerStock]
		, [TaxRate] = Source.[TaxRate]
		, [UnitPrice] = Source.[UnitPrice]
when not matched 
    then insert (
		[StockItemName]
		, [SupplierID]
		, [UnitPackageID]
		, [OuterPackageID]
		, [QuantityPerOuter]
		, [TypicalWeightPerUnit]
		, [LeadTimeDays]
		, [IsChillerStock]
		, [TaxRate]
		, [UnitPrice]
		, [LastEditedBy])
        values (Source.[StockItemName]
			, Source.[SupplierID]
			, Source.[UnitPackageID]
			, Source.[OuterPackageID]
			, Source.[QuantityPerOuter]
			, Source.[TypicalWeightPerUnit]
			, Source.[LeadTimeDays]
			, Source.[IsChillerStock]
			, Source.[TaxRate]
			, Source.[UnitPrice]
			, 3);

---Вопросы?---

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

select 
	StockItemID as [@ID]
	, StockItemName as [Name]
	, SupplierID as [Supplier/ID]
	, ColorID as [Color/ID]
	, UnitPackageID as [Package/UnitID]
	, OuterPackageID as [Package/OuterID]
	, Brand as [Brand]
	, Size as [Size]
	, LeadTimeDays as [LeadTime]
	, QuantityPerOuter as [Package/Quantity]
	, IsChillerStock as [IsChillerStock]
	, Barcode as [Barcode]
	, TaxRate as [TaxRate]
	, UnitPrice as [Pricing/Unit]
	, TypicalWeightPerUnit as [Package/Weight]
	, RecommendedRetailPrice as [Pricing/Retail]
	, TypicalWeightPerUnit as [Weight/PerUnit]
	, MarketingComments as [MarketingComments]
	, InternalComments as [InternalComments]
	, Photo as [Photo]
	, CustomFields as [CustomFields]
	, Tags as [Tags]
	, SearchDetails as [SearchDetails]
	, LastEditedBy as [LastEdited/By]
	, ValidFrom as [Valid/From]
	, ValidTo as [Valid/To]
from Warehouse.StockItems
for xml path('StockItem'), root('StockItems')

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select distinct
	t0.StockItemID
	, t0.StockItemName
	, t1.CountryOfManufacture
	, t1.FirstTag
from [Warehouse].[StockItems] as t0
outer apply openjson(CustomFields) with (
	CountryOfManufacture nvarchar(max) '$.CountryOfManufacture'
	, FirstTag nvarchar(max) '$.Tags[0]'
) t1

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

select distinct
	t0.StockItemID
	, t0.StockItemName
from [Warehouse].[StockItems] as t0
outer apply openjson(CustomFields, '$.Tags') t1
where t1.value = 'Vintage'