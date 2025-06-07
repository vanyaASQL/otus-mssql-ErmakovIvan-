/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

declare @Columns nvarchar(max) = '', @sql nvarchar(max);

select @Columns = stuff((
    select
        ',' + quotename(left(t0.CustomerName, 50))
    from Sales.Customers t0
    join Sales.Invoices t1 on t0.CustomerID = t1.CustomerID
    group by t0.CustomerID, t0.CustomerName
    order by count(distinct t1.InvoiceID) desc
    for xml path(''), type
).value('.', 'nvarchar(max)'), 1, 1, '');

set @sql = N'
select 
    convert(varchar(10), MonthStart, 104) as MonthStart, ' + @Columns + '
from 
(
    select 
        convert(date, dateadd(month, datediff(month, 0, t1.InvoiceDate), 0)) AS MonthStart
        , left(t0.CustomerName, 50) as CustomerName
        , count(distinct t1.InvoiceID) as PurchaseCount
    from Sales.Customers t0
    join Sales.Invoices t1 on t0.CustomerID = t1.CustomerID
    where t0.CustomerName in 
	(
        select top 10 -- если не ограничить вывод данных выходит ошибка
            t0.CustomerName
        from Sales.Customers t0
        join Sales.Invoices t1 on t0.CustomerID = t1.CustomerID
        group by t0.CustomerID, t0.CustomerName
        order by count(distinct t1.InvoiceID) desc
    )
    group by 
        convert(date, dateadd(month, datediff(month, 0, t1.InvoiceDate), 0))
        , left(t0.CustomerName, 50)
) as SourceTable
pivot 
(
    sum(PurchaseCount)
    for CustomerName in (' + @Columns + ')
) as PivotTable
order by MonthStart;
';

exec sp_executesql @sql;