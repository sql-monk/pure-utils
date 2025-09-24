# pure utils

### ������ ���������
1. [DESCRIPTION & MS_DESCRIPTION] - 15 �������/��������
2. [OBJECTS & METADATA] - 25 �������
3. [PARAMETERS] - 6 �������  
4. [COLUMNS] - 8 �������
5. [STRING & TEXT PROCESSING] - 12 �������
6. [SCRIPT GENERATION] - 8 �������
7. [TEMP TABLES] - 2 �������
8. [MODULES & CODE ANALYSIS] - 18 �������
9. [ERROR HANDLING] - 2 �������/��������� + 1 �������
10. [EXTENDED EVENTS (XE)] - 8 �������/��������
11. [EXTENDED PROPERTIES] - 12 ��������
12. [INDEXES] - 10 �������/��������
13. [TABLES] - 4 �������
14. [LOGS & EVENTS] - 6 ������������ + �������
15. [EXECUTION MONITORING] - 8 �������/������������
16. [PERMISSIONS] - 2 �������
17. [HISTORY] - 3 �������

---

## DESCRIPTION & MS_DESCRIPTION

### ���������� ������� �������������� (15 ��'����)

**����������� ���������� ����� � ���������:**
- `modulesGetDescriptionFromComments` - ������ ����� � �������������� ���������
- `modulesGetDescriptionFromCommentsLegacy` - ������ ����� � ������� ������� ���������
- `stringSplitMultiLineComment` - ������� ������������ ��������
- `modulesSetDescriptionFromComments` - ����������� ���������� ����� � ���������
- `modulesSetDescriptionFromCommentsLegacy` - ��� ������� �������

**����� ������������ ����� (12 ��������):**
- `metadataSetTableDescription` - ����� �������
- `metadataSetColumnDescription` - ����� �������
- `metadataSetProcedureDescription` - ����� ��������
- `metadataSetFunctionDescription` - ����� �������
- `metadataSetViewDescription` - ����� ������������
- `metadataSetTriggerDescription` - ����� �������
- `metadataSetParameterDescription` - ����� ���������
- `metadataSetIndexDescription` - ����� �������
- `metadataSetSchemaDescription` - ����� ����
- `metadataSetDataspaceDescription` - ����� �������� �����
- `metadataSetFilegroupDescription` - ����� �������� ����
- `metadataSetExtendedProperty` - ����������� ���������

**��������� �����:**
- `metadataGetDescriptions` - ��������� ����� ��'����
- `metadataGetExtendedProperiesValues` - ������� ���������� ������������

### �������� ������������:
```sql
-- ����������� ������������ ����� � ���������
EXEC util.modulesSetDescriptionFromComments 'dbo.MyProcedure';

-- ����� ������������ �����
EXEC util.metadataSetTableDescription @table = 'dbo.Users', @description = '������� ������������ �������';
EXEC util.metadataSetColumnDescription @object = 'dbo.Users', @column = 'Email', @description = 'Email ������ �����������';

-- ��������� ��� �����
SELECT * FROM util.metadataGetDescriptions('dbo.Users', NULL);
SELECT * FROM util.metadataGetExtendedProperiesValues('dbo.Users', NULL, 'MS_Description');
```

---

## OBJECTS & METADATA

### ����������� ������� ��� ��'���� (25 �������)
**������ �������:**
- `metadataGetObjectName` - ��������� ����� ��'���� �� ID
- `metadataGetObjectType` - ��� ��'���� �� ������
- `metadataGetObjectsType` - ���� ������ ��'����
- `metadataGetAnyId` - ����������� ��������� ID ����-����� ��'����
- `metadataGetAnyName` - ����������� ��������� ����� ����-����� ��'����

**������������ ��'����:**
- `metadataGetClassByName` - ��� ����� �� ������
- `metadataGetClassName` - ����� ����� �� �����

**������������ �������:**
- `metadataGetCertificateName` - ����� �����������
- `metadataGetDataspaceId` / `metadataGetDataspaceName` - �������� �����
- `metadataGetPartitionFunctionId` / `metadataGetPartitionFunctionName` - ������� ���������

### �������� ������������:
```sql
-- ������� ������ � ��'������
SELECT util.metadataGetObjectName(OBJECT_ID('dbo.Users')); -- [dbo].[Users]
SELECT util.metadataGetObjectType('dbo.Users'); -- 'U' (User Table)
SELECT * FROM util.metadataGetObjectsType('dbo.Users,dbo.Orders,dbo.GetUserData');

-- ���������� �������
SELECT util.metadataGetAnyId('dbo.Users', 'OBJECT'); -- object_id
SELECT util.metadataGetAnyId('dbo.Users', 'OBJECT', 'Email'); -- column_id
SELECT util.metadataGetAnyName(OBJECT_ID('dbo.Users'), 0, '1'); -- [dbo].[Users]

-- ������������
SELECT util.metadataGetClassByName('OBJECT_OR_COLUMN'); -- 1
SELECT util.metadataGetClassName(1); -- 'OBJECT_OR_COLUMN'
```

---

## PARAMETERS

### ������� ��� ������ � ����������� (6 �������)
- `metadataGetParameters` - �������� ���������� ��� ��������� ��������/�������
- `metadataGetParameterId` - ID ��������� �� ������
- `metadataGetParameterName` - ����� ��������� �� ID

### �������� ������������:
```sql
-- ��������� ��� ��������� ���������
SELECT * FROM util.metadataGetParameters('util.errorHandler');
SELECT * FROM util.metadataGetParameters(NULL); -- �� ��������� ��� ��'����

-- ������ � ����������� �����������
SELECT util.metadataGetParameterId('dbo.MyProc', '@userId');
SELECT util.metadataGetParameterName(OBJECT_ID('dbo.MyProc'), 1);
```

---

## COLUMNS

### ������� ��� ������ � ��������� (8 �������)
- `metadataGetColumns` - �������� ���������� ��� �������
- `metadataGetColumnId` - ID ������� �� ������
- `metadataGetColumnName` - ����� ������� �� ID
- `tablesGetIndexedColumns` - ����� ������������ �������

### �������� ������������:
```sql
-- �������� ���������� ��� �������
SELECT * FROM util.metadataGetColumns('dbo.Users');
SELECT * FROM util.metadataGetColumns(NULL); -- �� ������� ��� �������

-- ������ � ����������� ���������
SELECT util.metadataGetColumnId('dbo.Users', 'Email');
SELECT util.metadataGetColumnName('dbo.Users', 1);

-- ����� ������������ �������
SELECT * FROM util.tablesGetIndexedColumns('dbo.Users');
-- ������: IndexName, KeyOrdinal, IsIncludedColumn, IsUnique, IsPrimaryKey
```

---

## STRING & TEXT PROCESSING

### ������� ��� ������� ������ (12 �������)

**�������� ������:**
- `stringSplitToLines` - �������� ������ �� �����
- `modulesSplitToLines` - �������� ���� ������ �� �����
- `stringSplitMultiLineComment` - ������� �������������� ���������

**����� �������:**
- `stringFindCommentsPositions` - �� �������� � �����
- `stringFindInlineCommentsPositions` - ���������� ��������
- `stringFindLinesPositions` - ������� ��� �����
- `stringFindMultilineCommentsPositions` - ������������ ��������
- `stringGetCreateLineNumber` - ����� � CREATE

### �������� ������������:
```sql
-- �������� ������ �� �����
DECLARE @code NVARCHAR(MAX) = 'CREATE PROCEDURE test AS
SELECT * FROM users;
-- ��������
SELECT COUNT(*) FROM orders;';

SELECT * FROM util.stringSplitToLines(@code, 1); -- ��� ������� �����
SELECT * FROM util.stringGetCreateLineNumber(@code, 1); -- ����� ����� � CREATE

-- ����� ���������
SELECT * FROM util.stringFindCommentsPositions(@code, 1);
SELECT * FROM util.stringFindInlineCommentsPositions(@code, 1);

-- ������� �������������� ���������
DECLARE @comment NVARCHAR(MAX) = '/*
# Description
Test function
# Parameters
@id INT - identifier
*/';
SELECT * FROM util.stringSplitMultiLineComment(@comment);
```

---

## SCRIPT GENERATION

### ������� ��� ��������� DDL ������� (8 �������)

**������� �������:**
- `indexesGetScript` - DDL ��� ��������� �������
- `indexesGetScriptConventionRename` - ������� �������������� �������
- `indexesGetConventionNames` - ������������ ����� �������

**������� �������:**
- `tablesGetScript` - ������ DDL �������

### �������� ������������:
```sql
-- ��������� ������� �������
SELECT * FROM util.indexesGetScript('dbo.Users', NULL); -- �� ������� �������
SELECT * FROM util.indexesGetScript('dbo.Users', 'IX_Users_Email'); -- ���������� ������

-- ������� �������������� �� �����������
SELECT * FROM util.indexesGetConventionNames('dbo.Users', NULL); -- ������������
SELECT * FROM util.indexesGetScriptConventionRename('dbo.Users', NULL); -- �������

-- ������ DDL �������
SELECT createScript FROM util.tablesGetScript('dbo.Users');
```

---

## TEMP TABLES


����������� ��� **������������� ��������� ���������� �������** �� ����� ������ SQL ������ �� �������� ��'���� ���� �����. ������� ����������� ��������� ������� SQL Server `sys.dm_exec_describe_first_result_set` ��� ������������� ���������� ��������� ������������� ������ �� ��������� ���������� DDL �������.

### ������ ���������:
- **����������� ���������� ���� �����** �� nullable constraints
- **ϳ������� ���������������� ������** ����� sp_executesql ������
- **Flexible ����������** ���������� �������

### ������� ��� ��������� ���������� ������� (4 �������)

**Inline ������� (���������� TABLE):**
- `stringGetCreateTempScriptInline` - ����� SQL ������ � ����������� TABLE

**Scalar ������� (���������� NVARCHAR(MAX)):**
- `stringGetCreateTempScript` - ����� SQL ������ � ����������� �������

### ��������� ���� �������:

#### stringGetCreateTempScriptInline
- **�����������**: ������ SQL ����� �� ������ CREATE TABLE DDL
- **���������**: sys.dm_exec_describe_first_result_set � ��������� ���������
- **���������**: TABLE � �������� createScript
- **��������**: ����� ��������������� � JOIN �� ���������

#### stringGetCreateTempScript  
- **�����������**: Scalar �������� ��� stringGetCreateTempScriptInline
- **���������**: NVARCHAR(MAX) - ������� �� ��������� ������
- **��������**: ������ ��� ��������������� ��������� ����� sp_executesql

### �������� ������������:

#### ����� ������ ������������
```sql
-- 1. ��������� temp ������� � �������� SELECT
SELECT createScript 
FROM util.stringGetCreateTempScriptInline(
    'SELECT UserID, UserName, Email, CreatedDate FROM dbo.Users WHERE IsActive = 1', 
    '#ActiveUsers', 
    NULL
);

-- 2. ������������ scalar ������� ��� ���������
DECLARE @script NVARCHAR(MAX) = util.stringGetCreateTempScript(
    'SELECT OrderID, CustomerID, OrderDate, TotalAmount FROM dbo.Orders', 
    '#OrdersTemp', 
    NULL
);
EXEC sp_executesql @script;
-- ����� ����� ��������������� #OrdersTemp (**��� �� ��������� ��� ������� ��������**)

-- 3. ��������� temp ������� � ���������� ���������
DECLARE @procScript NVARCHAR(MAX) = util.objectGetCreateTempScript(
    'dbo.GetMonthlyReport', 
    '#MonthlyReportData', 
    NULL
); 
EXEC sp_executesql @procScript;
INSERT INTO #MonthlyReportData EXEC dbo.GetMonthlyReport @Month = 12, @Year = 2024;
```

#### �������������� ������
```sql
-- ϳ������� ��������� ��� �������� ������
DECLARE @params NVARCHAR(MAX) = '@StartDate DATETIME, @EndDate DATETIME, @MinAmount DECIMAL(10,2)';
DECLARE @query NVARCHAR(MAX) = N'
SELECT 
    o.OrderID,
    o.CustomerID, 
    c.CustomerName,
    o.OrderDate,
    o.TotalAmount,
    od.ProductCount
FROM dbo.Orders o
JOIN dbo.Customers c ON o.CustomerID = c.CustomerID
LEFT JOIN (
    SELECT OrderID, COUNT(*) as ProductCount 
    FROM dbo.OrderDetails 
    GROUP BY OrderID
) od ON o.OrderID = od.OrderID
WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
    AND o.TotalAmount >= @MinAmount';

-- ��������� ������� � �����������
SELECT createScript 
FROM util.stringGetCreateTempScriptInline(@query, '#FilteredOrders', @params);

-- ������������ ������������� �������
DECLARE @createScript NVARCHAR(MAX) = util.stringGetCreateTempScript(@query, '#FilteredOrders', @params);
EXEC sp_executesql @createScript;

-- ���������� ������
INSERT INTO #FilteredOrders
EXEC sp_executesql @query, @params, 
    @StartDate = '2024-01-01', 
    @EndDate = '2024-12-31', 
    @MinAmount = 100.00;
```

#### ������ � ��������� �� �����������
```sql
-- ��������� temp ������� ��� table-valued �������
SELECT createScript 
FROM util.objectGetCreateTempScriptInline('dbo.GetUserAnalytics', '#UserAnalytics', NULL);

-- ��������� temp ������� ��� ��������� � �����������
DECLARE @procScript NVARCHAR(MAX) = util.objectGetCreateTempScript(
    'dbo.GetSalesReport', 
    '#SalesReportTemp', 
    NULL
);
EXEC sp_executesql @procScript;

-- ���������� ����� ���������
INSERT INTO #SalesReportTemp 
EXEC dbo.GetSalesReport @RegionID = 5, @Quarter = 4, @Year = 2024;

-- �������� ������ � ������
SELECT Region, SUM(SalesAmount) as TotalSales
FROM #SalesReportTemp
GROUP BY Region
ORDER BY TotalSales DESC;
```

#### ������ ������ �� ����������
```sql
-- ��������� temp ������� � CTE �� �������� ���������
DECLARE @complexQuery NVARCHAR(MAX) = N'
WITH RankedOrders AS (
    SELECT 
        CustomerID,
        OrderDate,
        TotalAmount,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate DESC) as OrderRank,
        LAG(TotalAmount) OVER (PARTITION BY CustomerID ORDER BY OrderDate) as PrevOrderAmount
    FROM dbo.Orders
    WHERE OrderDate >= DATEADD(year, -1, GETDATE())
),
CustomerMetrics AS (
    SELECT 
        CustomerID,
        COUNT(*) as OrderCount,
        AVG(TotalAmount) as AvgOrderAmount,
        MAX(TotalAmount) as MaxOrderAmount,
        SUM(TotalAmount) as TotalSpent
    FROM RankedOrders
    GROUP BY CustomerID
)
SELECT 
    ro.CustomerID,
    c.CustomerName,
    ro.OrderDate as LastOrderDate,
    ro.TotalAmount as LastOrderAmount,
    ro.PrevOrderAmount,
    cm.OrderCount,
    cm.AvgOrderAmount,
    cm.TotalSpent,
    CASE 
        WHEN cm.TotalSpent > 10000 THEN ''VIP''
        WHEN cm.TotalSpent > 5000 THEN ''Premium''
        ELSE ''Standard''
    END as CustomerTier
FROM RankedOrders ro
JOIN dbo.Customers c ON ro.CustomerID = c.CustomerID
JOIN CustomerMetrics cm ON ro.CustomerID = cm.CustomerID
WHERE ro.OrderRank = 1';

-- ��������� �� ��������� ������� temp �������
DECLARE @script NVARCHAR(MAX) = util.stringGetCreateTempScript(@complexQuery, '#CustomerAnalytics', NULL);
EXEC sp_executesql @script;

-- ������������ �������� ���������
INSERT INTO #CustomerAnalytics
EXEC sp_executesql @complexQuery;

-- ����� �����
SELECT 
    CustomerTier,
    COUNT(*) as CustomerCount,
    AVG(TotalSpent) as AvgTotalSpent,
    AVG(OrderCount) as AvgOrderCount
FROM #CustomerAnalytics
GROUP BY CustomerTier
ORDER BY 
    CASE CustomerTier 
        WHEN 'VIP' THEN 1 
        WHEN 'Premium' THEN 2 
        ELSE 3 
    END;
```

#### �������� ������ ETL �� �������
```sql
-- ������� 1: ϳ�������� staging ������� ��� ETL
DECLARE @sourceQuery NVARCHAR(MAX) = N'
SELECT 
    CAST(SourceID as BIGINT) as SourceID,
    UPPER(LTRIM(RTRIM(SourceName))) as CleanedName,
    TRY_CAST(DateField as DATE) as ProcessedDate,
    CASE WHEN NumericField < 0 THEN 0 ELSE NumericField END as ValidatedAmount,
    HASHBYTES(''SHA2_256'', CONCAT(SourceID, SourceName, DateField)) as RowHash
FROM SourceSystem.dbo.RawData 
WHERE ImportDate = CAST(GETDATE() as DATE)
    AND SourceName IS NOT NULL';

-- ��������� staging �������
DECLARE @stagingScript NVARCHAR(MAX) = util.stringGetCreateTempScript(
    @sourceQuery, 
    '#StagingData', 
    NULL
);
EXEC sp_executesql @stagingScript;

-- ���������� �� �������
INSERT INTO #StagingData
EXEC sp_executesql @sourceQuery;

-- ������� 2: �������� ��������� temp ������� ��� ����
DECLARE @reportQuery NVARCHAR(MAX);
DECLARE @reportParams NVARCHAR(MAX) = '@ReportType NVARCHAR(50), @DateFrom DATE, @DateTo DATE';

SET @reportQuery = N'
SELECT 
    CASE @ReportType 
        WHEN ''Daily'' THEN FORMAT(TransactionDate, ''yyyy-MM-dd'')
        WHEN ''Weekly'' THEN FORMAT(TransactionDate, ''yyyy-\\W\\w-ww'')
        WHEN ''Monthly'' THEN FORMAT(TransactionDate, ''yyyy-MM'')
        ELSE ''Unknown''
    END as Period,
    COUNT(*) as TransactionCount,
    SUM(Amount) as TotalAmount,
    AVG(Amount) as AvgAmount,
    MIN(Amount) as MinAmount,
    MAX(Amount) as MaxAmount
FROM dbo.Transactions 
WHERE TransactionDate BETWEEN @DateFrom AND @DateTo
GROUP BY 
    CASE @ReportType 
        WHEN ''Daily'' THEN FORMAT(TransactionDate, ''yyyy-MM-dd'')
        WHEN ''Weekly'' THEN FORMAT(TransactionDate, ''yyyy-\\W\\w-ww'')
        WHEN ''Monthly'' THEN FORMAT(TransactionDate, ''yyyy-MM'')
        ELSE ''Unknown''
    END';

-- ��������� ������ ����� ���������
DECLARE @reportScript NVARCHAR(MAX) = util.stringGetCreateTempScript(
    @reportQuery, 
    '#DynamicReport', 
    @reportParams
);
EXEC sp_executesql @reportScript;
```

---

## ERROR HANDLING

### ���������� ������� ������� ������� (3 ��'����)
- `util.errorHandler` - ������������ �������� �������
- `util.errorLog` - �������������� ������ ������� � ������ ����������
- `util.help` - �������� ������� �� Pure Utils

### �������� ������������:
```sql
-- ������ ��������� �������
BEGIN TRY
    -- ���������� ��������
    EXEC dbo.BusinessProcedure;
END TRY
BEGIN CATCH
    EXEC util.errorHandler @attachment = '�������� ��������';
END CATCH

-- ����� �������
SELECT * FROM util.errorLog 
WHERE ErrorDateTime > DATEADD(DAY, -1, GETDATE())
ORDER BY ErrorDateTime DESC;

-- ������ �� ������
SELECT * FROM util.help('error');
```

---

## EXTENDED EVENTS (XE)

### ������� ���������� ����� Extended Events (15 ��'����)
**XE ���:**
- `utilsErrors` - ��� ��������� �������
- `utilsModulesUsers` - ��������� ��������� ������ �������������  
- `utilsModulesFaust` - ����������� ��������� Faust ������������
- `utilsModulesSSIS` - ���������� SSIS ������

**������� ��� ������� XE:**
- `util.xeGetErrors` - ������� ������� � XE �����
- `util.xeGetTargetFile` - ���������� ��� ������ ����� ����
- `util.xeGetLogsPath` - ��������� ������ �� ����

**������� ���������:**
- `util.executionModulesUsers/Faust/SSIS` - ��� ��������� ������
- `util.executionSqlText` - ��� ��������� SQL ������
- `util.xeOffsets` - ������� ������� XE �����

### �������� ������������:
```sql
-- ������� XE �����
EXEC util.xeCopyModulesToTable 'Users';

-- ����� ������� � XE
SELECT * FROM util.xeGetErrors(DATEADD(HOUR, -1, GETDATE()));

-- ��������� ��������� ������  
SELECT * FROM util.viewExecutionModulesUsers
WHERE EventTime > DATEADD(HOUR, -1, GETDATE());
```

---

## EXTENDED PROPERTIES

### ��������� ��� ������ � ����������� ������������� (12 ��������)
- `metadataSetTableDescription` - ����� �������
- `metadataSetColumnDescription` - ����� �������  
- `metadataSetProcedureDescription` - ����� ��������
- `metadataSetFunctionDescription` - ����� �������
- `metadataSetViewDescription` - ����� ������������
- `metadataSetTriggerDescription` - ����� �������
- `metadataSetParameterDescription` - ����� ���������
- `metadataSetIndexDescription` - ����� �������
- `metadataSetSchemaDescription` - ����� ����
- `metadataSetDataspaceDescription` - ����� �������� �����
- `metadataSetFilegroupDescription` - ����� �������� ����
- `metadataSetExtendedProperty` - ����������� ���������

### �������� ������������:
```sql
-- ������������ ����� ����� ��'����
EXEC util.metadataSetTableDescription @table = 'dbo.Users', @description = '������� ������������';
EXEC util.metadataSetColumnDescription @object = 'dbo.Users', @column = 'Email', @description = 'Email �����������';
EXEC util.metadataSetProcedureDescription @procedure = 'dbo.GetUsers', @description = '��������� ������ ������������';

-- ����������� ������������ ����������
EXEC util.metadataSetExtendedProperty 
    @name = 'MS_Description', 
    @value = '�������� ������� �������',
    @level0type = 'SCHEMA', @level0name = 'dbo',
    @level1type = 'TABLE', @level1name = 'Orders';
```

---

## INDEXES

### ������� �� ��������� ��� ������ � ��������� (10 ��'����)
- `indexesGetScript` - ��������� DDL ������� �������
- `indexesGetConventionNames` - ������������ ����� �� �����������
- `indexesGetScriptConventionRename` - ������� ��������������
- `indexesGetMissing` - ����� ������� �������
- `indexesGetUnused` - ����� ������������������ �������
- `indexesGetDuplicates` - ��������� �������� �������

### �������� ������������:
```sql
-- ��������� ������� �������
SELECT * FROM util.indexesGetScript('dbo.Users', NULL);

-- ����� ������������ �� ����������
SELECT * FROM util.indexesGetConventionNames('dbo.Users', NULL);

-- ����� ���������� �������
SELECT * FROM util.indexesGetMissing('dbo.Users');
SELECT * FROM util.indexesGetUnused('dbo.Users');
SELECT * FROM util.indexesGetDuplicates('dbo.Users');
```

---

## TABLES

### ������� ��� ������ � ��������� (4 �������)
- `tablesGetScript` - ������ DDL ������ �������
- `tablesGetIndexedColumns` - ����� ������������ �������
- `tablesGetConstraints` - ���������� ��� ���������
- `tablesGetDependencies` - ��������� �������

### �������� ������������:
```sql
-- ������ DDL �������
SELECT createScript FROM util.tablesGetScript('dbo.Users');

-- ����� ���������
SELECT * FROM util.tablesGetIndexedColumns('dbo.Users');
SELECT * FROM util.tablesGetConstraints('dbo.Users');
SELECT * FROM util.tablesGetDependencies('dbo.Users');
```

---

## LOGS & EVENTS

### ������������� ��� ������ ���� �� ���� (6 ������������ + �������)
- `util.viewErrorLog` - ������������ �������� �������
- `util.viewExecutionStats` - ���������� ���������
- `util.viewPerformanceCounters` - ��������� �������������
- `util.viewSessionActivity` - ��������� ����
- `util.viewBlockingChains` - ������� ���������
- `util.viewWaitStats` - ���������� ���������

### �������� ������������:
```sql
-- ����� ������� �������
SELECT * FROM util.viewErrorLog 
WHERE ErrorDateTime > DATEADD(HOUR, -1, GETDATE());

-- ��������� �������������
SELECT * FROM util.viewPerformanceCounters;
SELECT * FROM util.viewWaitStats;

-- ����� ���������
SELECT * FROM util.viewBlockingChains;
```

---

## EXECUTION MONITORING

### ������� �� ������������� ��� ���������� ��������� (8 ��'����)
- `util.getActiveQueries` - ������ ������ ������
- `util.getLongRunningQueries` - ����������� ��������
- `util.getBlockedProcesses` - ���������� �������
- `util.viewExecutionPlans` - ����� ���������
- `util.viewResourceUsage` - ������������ �������
- `util.viewQueryStats` - ���������� ������

### �������� ������������:
```sql
-- ��������� ������� ���������
SELECT * FROM util.getActiveQueries();
SELECT * FROM util.getLongRunningQueries(30); -- ����� 30 ������

-- ����� �������������
SELECT * FROM util.viewQueryStats 
WHERE ExecutionCount > 100
ORDER BY AvgDuration DESC;

-- ������������ �������
SELECT * FROM util.viewResourceUsage;
```

---

## PERMISSIONS

### ������� ��� ������ ������� (2 �������)
- `permissionsGetUserRights` - ����� ����������� �����������
- `permissionsGetObjectAccess` - ������ �� ��'����

### �������� ������������:
```sql
-- ����� ���� �����������
SELECT * FROM util.permissionsGetUserRights('domain\username');

-- �������� ������� �� ��'����
SELECT * FROM util.permissionsGetObjectAccess('dbo.Users');
```

---

## HISTORY

### ������� ��� ������ � ������ (3 �������)
- `historyGetSchemaChanges` - ���� � ���� ��
- `historyGetDataChanges` - ���� � ����� (CDC/CT)
- `historyGetBackupInfo` - ���������� ��� ������� ��ﳿ

### �������� ������������:
```sql
-- ����� ��� � ����
SELECT * FROM util.historyGetSchemaChanges(DATEADD(DAY, -7, GETDATE()));

-- ���������� ��� ������
SELECT * FROM util.historyGetBackupInfo('MyDatabase');