/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
set statistics time, io on
select 
    t0.InvoiceID id
    , t2.CustomerName customer_name
    , t0.InvoiceDate sale_date
    , sum(t1.ExtendedPrice) sale_amount
    , (
        select 
			sum(t4.ExtendedPrice)
        from Sales.Invoices t3
        inner join Sales.InvoiceLines t4 on t3.InvoiceID = t4.InvoiceID
        where dateadd(month, datediff(month, 0, t3.InvoiceDate), 0) <= dateadd(month, datediff(month, 0, t0.InvoiceDate), 0)
			AND t3.InvoiceDate >= '2015-01-01'
    ) running_total
from Sales.Invoices t0
inner join Sales.InvoiceLines t1 ON t0.InvoiceID = t1.InvoiceID
inner join Sales.Customers t2 ON t0.CustomerID = t2.CustomerID
where t0.InvoiceDate >= '2015-01-01'
group by t0.InvoiceID, t2.CustomerName, t0.InvoiceDate
order by t0.InvoiceDate;



/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

select 
    t0.InvoiceID id
    , t2.CustomerName customer_name
    , t0.InvoiceDate sale_date
    , sum(t1.ExtendedPrice) sale_amount
    , sum(sum(t1.ExtendedPrice)) over(order by dateadd(month, datediff(month, 0, InvoiceDate), 0)) running_total
from Sales.Invoices t0
inner join Sales.InvoiceLines t1 ON t0.InvoiceID = t1.InvoiceID
inner join Sales.Customers t2 ON t0.CustomerID = t2.CustomerID
where t0.InvoiceDate >= '2015-01-01'
group by t0.InvoiceID, t2.CustomerName, t0.InvoiceDate
order by t0.InvoiceDate;

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

;with cte as
(
	select
		dt
		, [StockItemID]
		, sm
		, row_number() over(partition by dt order by dt, sm desc) as rw
	from 
	(
		select
			dateadd(month, datediff(month, 0, t0.InvoiceDate), 0) as dt
			, t1.[StockItemID]
			, sum(t1.[Quantity]) as sm
		from [WideWorldImporters].[Sales].[Invoices] t0
		left join [Sales].[InvoiceLines] t1 on t1.InvoiceID = t0.InvoiceID
		where t0.InvoiceDate >= '2016-01-01'
		group by dateadd(month, datediff(month, 0, t0.InvoiceDate), 0)
			, t1.[StockItemID]
	) t
)

select 
	cast(t0.dt as date) as Дата
	, t1.StockItemName as Наименование
	, t0.sm as Количество
from cte t0
left join [Warehouse].[StockItems] t1 on t1.StockItemID = t0.StockItemID
where rw = 1 or rw = 2 
order by dt

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select
	StockItemID
	, StockItemName
	, Brand
	, UnitPrice
	, row_number() over(partition by StockItemName order by StockItemName) as Нумерация
	, count(*) over() as ОбщееКоличествоТоваров
	, count(*) over(partition by left(StockItemName, 1)) as ОтПервойБуквы
	, lead(StockItemID, 1) over(order by StockItemName) as Следующий
	, lag(StockItemID, 1) over(order by StockItemName) as Предыдущий
	, isnull(lag(StockItemName, 2) over(order by StockItemName), 'No Items') as На2Предыдущих
	, ntile(30) over(order by TypicalWeightPerUnit) as [30Групп]
from [WideWorldImporters].[Warehouse].[StockItems]

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

;with cte as
(
	select distinct
		t0.PersonId as ИД_Продавец
		, t0.FullName as ФИОПродавца
		, last_value(t1.CustomerID) over(order by t1.SalespersonPersonID) as ИД_Клиент
		, last_value(t1.InvoiceID) over(order by t1.SalespersonPersonID) as ID_Продажи
	from [WideWorldImporters].[Application].[People] t0
	left join [WideWorldImporters].[Sales].[Invoices] t1 on  t1.SalespersonPersonID = t0.PersonID
	where t0.IsSalesperson = 1
)

select
	t0.ИД_Продавец
	, t0.ФИОПродавца
	, t0.ИД_Клиент
	, t1.CustomerName as НаименованиеКлиента
	, cast(t2.[LastEditedWhen] as date) as ДатаПродажи
	, sum([Quantity]*[UnitPrice]) as СуммаСделки
from cte t0
left join [WideWorldImporters].[Sales].[Customers] t1 on t1.CustomerID = t0.ИД_Клиент
left join [WideWorldImporters].[Sales].[InvoiceLines] t2 on t2.InvoiceID = t0.ID_Продажи
group by t0.ИД_Продавец
	, t0.ФИОПродавца
	, t0.ИД_Клиент
	, t1.CustomerName 
	, t2.[LastEditedWhen]
order by 1

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

;with cte as
(
	select
		t0.CustomerID ИДКлиента
		, t1.StockItemId ИДТовара
		, t1.UnitPrice ЦенаТовара
		, t0.InvoiceDate ДатаПокупки
		, dense_rank() over(partition by t0.CustomerID order by t1.UnitPrice desc) as rw
	from [WideWorldImporters].[Sales].[Invoices] t0
	left join [Sales].[InvoiceLines] t1 on t1.InvoiceID = t0.InvoiceID
)

select
	ИДКлиента
	, t1.CustomerName as НазваниеКлиента
	, ИДТовара
	, ЦенаТовара
	, ДатаПокупки
from cte t0
left join [Sales].[Customers] t1 on t1.CustomerID = t0.ИДКлиента
where rw = 1 or rw = 2
order by 1, 4 desc