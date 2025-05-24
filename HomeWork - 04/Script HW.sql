/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

TODO: 
-- подзапрос
select
	PersonID [ИД Сотрудника]
	, FullName [Полное имя]
from [WideWorldImporters].[Application].[People]
where PersonID not in (select SalespersonPersonID from [Sales].[Orders] where OrderDate = '2015-07-04')
	and IsSalesperson = 1

-- cte
;with cte as
(
	select
		SalespersonPersonID [ИД Сотрудника]
	from [Sales].[Orders]
	where OrderDate = '2015-07-04'
)

select
	PersonID [ИД Сотрудника]
	, FullName [Полное имя]
from [WideWorldImporters].[Application].[People] t0
left join cte t1 on t1.[ИД Сотрудника] = t0.PersonID
where IsSalesperson = 1 and t1.[ИД Сотрудника] is null


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

TODO: 
-- подзапрос №1
select
	StockItemID
	, StockItemName
	, UnitPrice
from [Warehouse].[StockItems]
where UnitPrice = (select min(UnitPrice) from [Warehouse].[StockItems])

-- подзапрос №2
select
	StockItemID
	, StockItemName
	, UnitPrice
from [Warehouse].[StockItems]
group by StockItemID
	, StockItemName
	, UnitPrice
having UnitPrice = (select min(UnitPrice) from [Warehouse].[StockItems])

-- cte
;with cte as 
(
	select
		min(UnitPrice) [МинЦена]
	from [Warehouse].[StockItems]
)

select
	StockItemID
	, StockItemName
	, UnitPrice
from [Warehouse].[StockItems] t0
where exists (select * from cte t1 where t0.UnitPrice=t1.МинЦена)

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

TODO:
-- подзапрос
select
	t0.CustomerID
	, CustomerName
from [Sales].[Customers] t0
inner join
(
	select top 5 with ties
		CustomerID
		, max(TransactionAmount) [Платеж]
	from [WideWorldImporters].[Sales].[CustomerTransactions]
	group by CustomerID
	order by 2 desc
) t1 on t1.CustomerID=t0.CustomerID
	

-- cte
;with cte as 
(
	select top 5 with ties
		CustomerID
		, max(TransactionAmount) [Платеж]
	from [WideWorldImporters].[Sales].[CustomerTransactions]
	group by CustomerID
	order by 2 desc
)

select
	t0.CustomerID
	, CustomerName
from [Sales].[Customers] t0
inner join cte t1 on t1.CustomerID=t0.CustomerID

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

TODO:
-- подзапрос
select
	t4.CityID
	, t4.CityName
	, t5.FullName
from [Sales].[InvoiceLines] t0
inner join 
(
	select top 3 with ties
		[StockItemID]
	from [Warehouse].[StockItems]
	order by [UnitPrice] desc
) t1 on t0.StockItemID = t1.StockItemID
left join [Sales].[Invoices] t2 on t2.InvoiceID = t0.InvoiceID
left join [Sales].[Customers] t3 on t3.CustomerID = t2.CustomerID
left join [Application].[Cities] t4 on t4.CityID = t3.DeliveryCityID
left join [Application].[People] t5 on t5.PersonID = t2.PackedByPersonID

-- cte
;with cte as 
(
	select top 3 with ties
		[StockItemID]
	from [Warehouse].[StockItems]
	order by [UnitPrice] desc
)

select
	t4.CityID
	, t4.CityName
	, t5.FullName
from [Sales].[InvoiceLines] t0
inner join cte t1 on t0.StockItemID = t1.StockItemID
left join [Sales].[Invoices] t2 on t2.InvoiceID = t0.InvoiceID
left join [Sales].[Customers] t3 on t3.CustomerID = t2.CustomerID
left join [Application].[Cities] t4 on t4.CityID = t3.DeliveryCityID
left join [Application].[People] t5 on t5.PersonID = t2.PackedByPersonID