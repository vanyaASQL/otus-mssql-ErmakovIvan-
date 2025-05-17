/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
	year(t0.[InvoiceDate]) as ГодПродажи
	, month(t0.[InvoiceDate]) as МесяцПродажи
	, avg(t1.UnitPrice) as СредняяЦена
	, sum(t1.UnitPrice * t1.Quantity) as ОбщаяСумма
from [WideWorldImporters].[Sales].[Invoices] t0
left join [WideWorldImporters].[Sales].[InvoiceLines] t1 on t1.InvoiceID = t0.InvoiceID
group by year(t0.[InvoiceDate])
	, month(t0.[InvoiceDate])
order by 1, 2

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
	year(t0.[InvoiceDate]) as ГодПродажи
	, month(t0.[InvoiceDate]) as МесяцПродажи
	, sum(t1.UnitPrice * t1.Quantity) as ОбщаяСумма
from [WideWorldImporters].[Sales].[Invoices] t0
left join [WideWorldImporters].[Sales].[InvoiceLines] t1 on t1.InvoiceID = t0.InvoiceID
group by year(t0.[InvoiceDate])
	, month(t0.[InvoiceDate])
having sum(t1.UnitPrice * t1.Quantity) > 4600000
order by 1, 2

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
    year(t0.InvoiceDate) as SaleYear
    , month(t0.InvoiceDate) as SaleMonth
    , t2.StockItemName as ItemName
    , sum(t1.UnitPrice * t1.Quantity) as TotalSalesAmount
    , min(t0.InvoiceDate) as FirstSaleDate
    , sum(t1.Quantity) as TotalQuantity
from Sales.Invoices t0
left join Sales.InvoiceLines t1 ON t0.InvoiceID = t1.InvoiceID
left join Warehouse.StockItems t2 ON t1.StockItemID = t2.StockItemID
group by year(t0.InvoiceDate)
	, month(t0.InvoiceDate)
	, t2.StockItemName
having sum(t1.Quantity) < 50
order by 1, 2, 3;

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/