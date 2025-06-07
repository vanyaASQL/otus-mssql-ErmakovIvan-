/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

select 
    format(dateadd(month, datediff(month, 0, t0.OrderDate), 0), 'dd.MM.yyyy') AS Month
    , count(*) AS OrderCount
    , substring(t1.CustomerName, charindex('(', t1.CustomerName) + 1, charindex(')', t1.CustomerName) - charindex('(', t1.CustomerName) - 1) AS CustomerLocation
into #TempOrders
from Sales.Orders t0
join Sales.Customers t1 ON t0.CustomerID = t1.CustomerID
where t1.CustomerID between 2 and 6
group by
    dateadd(month, datediff(month, 0, t0.OrderDate), 0),
    substring(t1.CustomerName, charindex('(', t1.CustomerName) + 1, charindex(')', t1.CustomerName) - charindex('(', t1.CustomerName) - 1);

select 
    Month,
    isnull([Sylvanite, MT], 0) AS [Sylvanite, MT],
    isnull([Peeples Valley, AZ], 0) AS [Peeples Valley, AZ],
    isnull([Medicine Lodge, KS], 0) AS [Medicine Lodge, KS],
    isnull([Gasport, NY], 0) AS [Gasport, NY],
    isnull([Jessie, ND], 0) AS [Jessie, ND]
from #TempOrders
pivot
(
    sum(OrderCount)
    for CustomerLocation in ([Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND])
) as PivotTable
order by cast(Month as date);


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select distinct
    t0.CustomerName
    , t1.Address
from Sales.Customers t0
cross apply (
    values 
        (t0.DeliveryAddressLine1)
        , (t0.DeliveryAddressLine2)
) t1(Address)
where t0.CustomerName like '%Tailspin Toys%'
    and t1.Address is not null
order by t0.CustomerName, t1.Address;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select distinct
    t0.CountryID
    , t0.CountryName
    , t1.CountryCode
from Application.Countries t0
cross apply (
    values 
        (cast(t0.IsoNumericCode as nvarchar(10)))
        , (t0.IsoAlpha3Code)
) t1(CountryCode)
where t1.CountryCode is not null
order by t0.CountryID, t1.CountryCode;

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select 
    t0.CustomerID
    , t0.CustomerName
    , t1.StockItemID
    , t1.UnitPrice
    , t1.InvoiceDate
from Sales.Customers t0
cross apply (
    select top 2
        t4.StockItemID,
        t3.UnitPrice,
        t2.InvoiceDate
    from Sales.Invoices t2
    join Sales.InvoiceLines t3 on t2.InvoiceID = t3.InvoiceID
    join Warehouse.StockItems t4 on t3.StockItemID = t4.StockItemID
    where t2.CustomerID = t0.CustomerID
    order by t3.UnitPrice desc, t2.InvoiceDate desc
) t1
order by t0.CustomerID, t1.UnitPrice desc, t1.InvoiceDate desc;