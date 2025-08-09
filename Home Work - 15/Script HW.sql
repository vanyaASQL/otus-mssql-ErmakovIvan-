USE WideWorldImporters;
GO

-- Включение Service Broker
ALTER DATABASE WideWorldImporters SET ENABLE_BROKER;
GO

-- Создание типа сообщения
CREATE MESSAGE TYPE ReportRequestMessage
VALIDATION = WELL_FORMED_XML;
GO

-- Создание контракта
CREATE CONTRACT ReportRequestContract
(ReportRequestMessage SENT BY INITIATOR);
GO

-- Создание очереди и сервиса для заявок
CREATE QUEUE ReportRequestQueue;
CREATE SERVICE ReportRequestService
ON QUEUE ReportRequestQueue (ReportRequestContract);
GO

-- Создание очереди и сервиса для ответов
CREATE QUEUE ReportResponseQueue;
CREATE SERVICE ReportResponseService
ON QUEUE ReportResponseQueue;
GO

-- Таблица для хранения готовых отчётов
CREATE TABLE Sales.CustomerOrderReports
(
    ReportID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    OrderCount INT NOT NULL,
    ReportGeneratedDateTime DATETIME DEFAULT GETDATE()
);
GO

CREATE PROCEDURE Sales.usp_CreateReportRequest
    @CustomerID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ConversationHandle UNIQUEIDENTIFIER;
    DECLARE @MessageBody XML;

    -- Формируем XML-сообщение
    SET @MessageBody = (
        SELECT @CustomerID AS CustomerID, @StartDate AS StartDate, @EndDate AS EndDate
        FOR XML RAW ('ReportRequest'), TYPE
    );

    -- Начинаем диалог
    BEGIN DIALOG CONVERSATION @ConversationHandle
        FROM SERVICE ReportRequestService
        TO SERVICE 'ReportResponseService'
        ON CONTRACT ReportRequestContract
        WITH ENCRYPTION = OFF;

    -- Отправляем сообщение
    SEND ON CONVERSATION @ConversationHandle
        MESSAGE TYPE ReportRequestMessage (@MessageBody);

    -- Закрываем диалог со стороны инициатора
    END CONVERSATION @ConversationHandle;
END;

-- Хранимая процедура для обработки очереди
CREATE PROCEDURE Sales.usp_ProcessReportQueue
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ConversationHandle UNIQUEIDENTIFIER;
    DECLARE @MessageTypeName NVARCHAR(256);
    DECLARE @MessageBody XML;
    DECLARE @CustomerID INT, @StartDate DATE, @EndDate DATE;

    WHILE (1 = 1)
    BEGIN
        -- Получаем следующее сообщение из очереди
        RECEIVE TOP(1)
            @ConversationHandle = conversation_handle,
            @MessageTypeName = message_type_name,
            @MessageBody = message_body
        FROM ReportRequestQueue;

        -- Выходим из цикла, если очередь пуста
        IF @@ROWCOUNT = 0 BREAK;

        -- Обработка сообщения
        IF @MessageTypeName = 'ReportRequestMessage'
        BEGIN
            -- Извлечение данных из XML
            SET @CustomerID = @MessageBody.value('(/ReportRequest/@CustomerID)[1]', 'INT');
            SET @StartDate = @MessageBody.value('(/ReportRequest/@StartDate)[1]', 'DATE');
            SET @EndDate = @MessageBody.value('(/ReportRequest/@EndDate)[1]', 'DATE');

            -- Формирование отчёта
            INSERT INTO Sales.CustomerOrderReports (CustomerID, StartDate, EndDate, OrderCount)
            SELECT 
                @CustomerID,
                @StartDate,
                @EndDate,
                COUNT(*) AS OrderCount
            FROM Sales.Orders o
            WHERE o.CustomerID = @CustomerID
                AND o.OrderDate BETWEEN @StartDate AND @EndDate;

            -- Закрытие диалога со стороны обработчика
            END CONVERSATION @ConversationHandle;
        END
        ELSE IF @MessageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
        BEGIN
            -- Закрытие диалога при получении EndDialog
            END CONVERSATION @ConversationHandle;
        END
        ELSE IF @MessageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
		 BEGIN
            -- Закрытие диалога при получении EndDialog
            END CONVERSATION @ConversationHandle;
        END
        ELSE IF @MessageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
        BEGIN
            -- Закрытие диалога при ошибке
            END CONVERSATION @ConversationHandle;
        END
    END
END;
GO

-- отправка заявки
EXEC Sales.usp_CreateReportRequest 
    @CustomerID = 1, 
    @StartDate = '2023-01-01', 
    @EndDate = '2023-12-31';

-- обработка очереди
EXEC Sales.usp_ProcessReportQueue

-- проверка отчета
SELECT * FROM Sales.CustomerOrderReports;

-- проверка очереди
SELECT * FROM ReportRequestQueue;
SELECT * FROM sys.conversation_endpoints;