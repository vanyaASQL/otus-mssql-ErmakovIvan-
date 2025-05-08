/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select
	StockItemID as [ИД товара]
	, StockItemName as [Наименование товара]
from Warehouse.StockItems
where StockItemName like '%urgent%'
	or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select distinct
	t0.SupplierID as [ИД Поставщика]
	, t0.SupplierName as [Наименование поставщика]
from [Purchasing].[Suppliers] t0
left join [Purchasing].[PurchaseOrders] t1 on t1.SupplierID=t0.SupplierID
where t1.SupplierID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

-- первый вариант
select distinct
	t0.OrderID as [Номер заказа]
	, format(t0.OrderDate, 'dd.MM.yyyy') as [Дата заказа]
	, datename(month, t0.OrderDate) as [Месяц]
	, datepart(quarter, t0.OrderDate) as [Квартал]
	, case 
		when month(t0.OrderDate) between 1 and 4 then N'Первая Треть'
		when month(t0.OrderDate) between 5 and 8 then N'Вторая Треть'
		else N'Третья Треть' end as [Треть года]
	, t2.CustomerName as [Имя заказчика]
from Sales.Orders t0
left join Sales.OrderLines t1 on t0.OrderID = t1.OrderID
left join Sales.Customers t2 on t0.CustomerID = t2.CustomerID
where (t1.UnitPrice > 100 or t1.Quantity > 20)
	and t0.PickingCompletedWhen is not null
order by 2, 4, 5;

-- второй вариант
select distinct
	t0.OrderID as [Номер заказа]
	, format(t0.OrderDate, 'dd.MM.yyyy') as [Дата заказа]
	, datename(month, t0.OrderDate) as [Месяц]
	, datepart(quarter, t0.OrderDate) as [Квартал]
	, case 
		when month(t0.OrderDate) between 1 and 4 then N'Первая Треть'
		when month(t0.OrderDate) between 5 and 8 then N'Вторая Треть'
		else N'Третья Треть' end as [Треть года]
	, t2.CustomerName as [Имя заказчика]
from Sales.Orders t0
left join Sales.OrderLines t1 on t0.OrderID = t1.OrderID
left join Sales.Customers t2 on t0.CustomerID = t2.CustomerID
where (t1.UnitPrice > 100 or t1.Quantity > 20)
	and t0.PickingCompletedWhen is not null
order by 2, 4, 5
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY;


/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select 
	t2.DeliveryMethodName as [Способ доставки]
	, t0.ExpectedDeliveryDate as [Дата доставки]
	, t1.SupplierName as [Имя поставщика]
	, t3.FullName as [Имя принимавшего]
from Purchasing.PurchaseOrders t0
left join Purchasing.Suppliers t1 on t0.SupplierID = t1.SupplierID
left join Application.DeliveryMethods t2 on t0.DeliveryMethodID = t2.DeliveryMethodID
left join Application.People t3 on t0.ContactPersonID = t3.PersonID
where t0.ExpectedDeliveryDate between '2013-01-01' and '2013-01-31'
	and t2.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
	and t0.IsOrderFinalized = 1
order by t0.ExpectedDeliveryDate;


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top (10)
	t0.OrderDate as [Дата заказа]
	, t1.CustomerName as [Имя клиента]
	, t2.FullName as [Имя сотрудника]
from Sales.Orders t0
left join Sales.Customers t1 on t0.CustomerID = t1.CustomerID
left join Application.People t2 on t0.SalespersonPersonID = t2.PersonID
order by t0.OrderDate desc;

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select distinct
	t0.CustomerID as [ID клиента]
	, t0.CustomerName as [Имя клиента]
	, t0.PhoneNumber as [Номер телефона]
from Sales.Customers t0
left join Sales.Orders t1 on t0.CustomerID = t1.CustomerID
left join Sales.OrderLines t2 on t1.OrderID = t2.OrderID
left join Warehouse.StockItems t3 on t2.StockItemID = t3.StockItemID
where t3.StockItemName = 'Chocolate frogs 250g'
order by t0.CustomerName;
