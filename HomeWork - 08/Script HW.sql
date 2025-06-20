/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

insert into Sales.Customers (
    CustomerName
    , BillToCustomerID
    , CustomerCategoryID
    , PrimaryContactPersonID
    , DeliveryMethodID
    , DeliveryCityID
    , PostalCityID
    , AccountOpenedDate
    , StandardDiscountPercentage
    , IsStatementSent
    , IsOnCreditHold
    , PaymentDays
    , PhoneNumber
    , FaxNumber
    , WebsiteURL
    , DeliveryAddressLine1
    , DeliveryPostalCode
    , PostalAddressLine1
    , PostalPostalCode
    , LastEditedBy
) output inserted.*
values
    ('New Customer 1', 1, 3, 1001, 9, 19586, 19586, '2025-06-01', 0.000, 0, 0, 7, '(123) 456-7890', '(123) 456-7891', 'http://newcustomer1.com', '123 Main St', '98052', 'PO Box 123', '98052', 1),
    ('New Customer 2', 1, 3, 1002, 9, 19586, 19586, '2025-06-02', 0.000, 0, 0, 7, '(123) 456-7892', '(123) 456-7893', 'http://newcustomer2.com', '456 Oak Ave', '98052', 'PO Box 456', '98052', 1),
    ('New Customer 3', 1, 3, 1003, 9, 19586, 19586, '2025-06-03', 0.000, 0, 0, 7, '(123) 456-7894', '(123) 456-7895', 'http://newcustomer3.com', '789 Pine Rd', '98052', 'PO Box 789', '98052', 1),
    ('New Customer 4', 1, 3, 1004, 9, 19586, 19586, '2025-06-04', 0.000, 0, 0, 7, '(123) 456-7896', '(123) 456-7897', 'http://newcustomer4.com', '101 Elm St', '98052', 'PO Box 101', '98052', 1),
    ('New Customer 5', 1, 3, 1005, 9, 19586, 19586, '2025-06-05', 0.000, 0, 0, 7, '(123) 456-7898', '(123) 456-7899', 'http://newcustomer5.com', '202 Cedar Ln', '98052', 'PO Box 202', '98052', 1);

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

delete from Sales.Customers where CustomerName = 'New Customer 3'


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

update t0
	set t0.CustomerName = 'Change Customer 4'
from Sales.Customers t0
where CustomerName = 'New Customer 4'

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

merge into Sales.Customers as target
using (
    select 
        N'New Customer Example' as CustomerName
        , 1 as BillToCustomerID
        , 3 as CustomerCategoryID
        , 1001 as PrimaryContactPersonID
        , 9 as DeliveryMethodID
        , 19586 as DeliveryCityID
        , 19586 as PostalCityID
        , '2025-06-07' as AccountOpenedDate
        , 0.000 as StandardDiscountPercentage
        , 0 as IsStatementSent
        , 0 as IsOnCreditHold
        , 7 as PaymentDays
        , '(123) 456-7800' as PhoneNumber
        , '(123) 456-7801' as FaxNumber
        , 'http://newcustomerexample.com' as WebsiteURL
        , '123 Example St' as DeliveryAddressLine1
        , '98052' as DeliveryPostalCode
        , 'PO Box 123' as PostalAddressLine1
        , '98052' as PostalPostalCode
        , 1 as LastEditedBy
) as source
on target.CustomerName = source.CustomerName
when matched then
    update set
        BillToCustomerID = source.BillToCustomerID
        , CustomerCategoryID = source.CustomerCategoryID
        , PrimaryContactPersonID = source.PrimaryContactPersonID
        , DeliveryMethodID = source.DeliveryMethodID
        , DeliveryCityID = source.DeliveryCityID
        , PostalCityID = source.PostalCityID
        , AccountOpenedDate = source.AccountOpenedDate
        , StandardDiscountPercentage = source.StandardDiscountPercentage
        , IsStatementSent = source.IsStatementSent
        , IsOnCreditHold = source.IsOnCreditHold
        , PaymentDays = source.PaymentDays
        , PhoneNumber = source.PhoneNumber
        , FaxNumber = source.FaxNumber
        , WebsiteURL = source.WebsiteURL
        , DeliveryAddressLine1 = source.DeliveryAddressLine1
        , DeliveryPostalCode = source.DeliveryPostalCode
        , PostalAddressLine1 = source.PostalAddressLine1
        , PostalPostalCode = source.PostalPostalCode
        , LastEditedBy = source.LastEditedBy
when not matched then
    insert (
        CustomerName
        , BillToCustomerID
        , CustomerCategoryID
        , PrimaryContactPersonID
        , DeliveryMethodID
        , DeliveryCityID
        , PostalCityID
        , AccountOpenedDate
        , StandardDiscountPercentage
        , IsStatementSent
        , IsOnCreditHold
        , PaymentDays
        , PhoneNumber
        , FaxNumber
        , WebsiteURL
        , DeliveryAddressLine1
        , DeliveryPostalCode
        , PostalAddressLine1
        , PostalPostalCode
        , LastEditedBy
    )
    values (
        source.CustomerName
        , source.BillToCustomerID
        , source.CustomerCategoryID
        , source.PrimaryContactPersonID
        , source.DeliveryMethodID
        , source.DeliveryCityID
        , source.PostalCityID
        , source.AccountOpenedDate
        , source.StandardDiscountPercentage
        , source.IsStatementSent
        , source.IsOnCreditHold
        , source.PaymentDays
        , source.PhoneNumber
        , source.FaxNumber
        , source.WebsiteURL
        , source.DeliveryAddressLine1
        , source.DeliveryPostalCode
        , source.PostalAddressLine1
        , source.PostalPostalCode
        , source.LastEditedBy
    )
output deleted.*, $action, inserted.*;


/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

/*
Не удается выполнить задание, так как SQL Server установлен с ограничениями на рабочий компьютер, с ограниченными правами пользователя. Доступа к правам администратора не имеется.
Из-за этого командная строка при написании выдает ошибку прав доступа. 
В лекции с помощью скриптов не было показано как этим можно пользоваться. Если есть какие-то варианты - прошу поделиться ими.
*/