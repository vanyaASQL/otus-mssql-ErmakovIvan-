-- Дано
set statistics time, io on
Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)    
FROM Sales.Orders AS ord
    JOIN Sales.OrderLines AS det
        ON det.OrderID = ord.OrderID
    JOIN Sales.Invoices AS Inv 
        ON Inv.OrderID = ord.OrderID
    JOIN Sales.CustomerTransactions AS Trans
        ON Trans.InvoiceID = Inv.InvoiceID
    JOIN Warehouse.StockItemTransactions AS ItemTrans
        ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
    AND (Select SupplierId
         FROM Warehouse.StockItems AS It
         Where It.StockItemID = det.StockItemID) = 12
    AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
        FROM Sales.OrderLines AS Total
            Join Sales.Orders AS ordTotal
                On ordTotal.OrderID = Total.OrderID
        WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
    AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

/*
При оптимизации был перестроен запрос: 
1. Переписаны кореллированные подзапросы в WHERE 
2. Убран DATEDIFF, так как он может мешать использованию индексов
3. Множественные join без явных индексов
4. Заменен подзапрос с SupplierId  на JOIN с Warehouse.StockItems
5. Заменен подзапрос с суммой по клиенту на CTE

Также проанализированы индексы и добавлены новые: 
CREATE INDEX IX_Orders_CustomerID ON Sales.Orders (CustomerID)
CREATE INDEX IX_OrderLines_OrderID_StockItemID ON Sales.OrderLines (OrderID, StockItemID) INCLUDE (UnitPrice, Quantity)
CREATE INDEX IX_Invoices_OrderID_BillToCustomerID ON Sales.Invoices (OrderID, BillToCustomerID) INCLUDE (InvoiceDate, CustomerID)
CREATE INDEX IX_StockItems_SupplierID ON Warehouse.StockItems (SupplierID) INCLUDE (StockItemID)

Получилось на выходе:
*/

set statistics time, io on
;WITH CustomerTotal AS 
(
    SELECT 
        ordTotal.CustomerID
    FROM Sales.OrderLines AS Total
    JOIN Sales.Orders AS ordTotal ON ordTotal.OrderID = Total.OrderID
    GROUP BY ordTotal.CustomerID
    HAVING SUM(Total.UnitPrice * Total.Quantity) > 250000
),

FilteredData AS 
(
    SELECT 
        ord.CustomerID,
        det.StockItemID,
        det.UnitPrice,
        det.Quantity,
        ord.OrderID
    FROM Sales.Orders AS ord
    JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
    JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
    JOIN Warehouse.StockItems AS It ON It.StockItemID = det.StockItemID
    JOIN CustomerTotal AS ct ON ct.CustomerID = Inv.CustomerID
    WHERE Inv.BillToCustomerID != ord.CustomerID
        AND It.SupplierID = 12
        AND Inv.InvoiceDate = ord.OrderDate
)
SELECT 
    CustomerID,
    StockItemID,
    SUM(UnitPrice) as TotalUnitPrice,
    SUM(Quantity) as TotalQuantity,
    COUNT(DISTINCT OrderID) as OrderCount
FROM FilteredData
GROUP BY CustomerID, StockItemID
ORDER BY CustomerID, StockItemID

/*
Улучшился план запроса, снизилось количество затраченного времени на выполнение запроса и снизилась нагрузка на работу ЦП.
*/