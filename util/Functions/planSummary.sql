/*
# Description
Парсить XML execution plan та витягує детальну інформацію про виконання запиту.
Функція аналізує ShowPlan XML та повертає метрики продуктивності, використання пам'яті,
інформацію про оптимізатор, попередження та рекомендації щодо індексів.

# Parameters
@plan XML - XML execution plan (actual або estimated) отриманий з sys.dm_exec_query_plan або SET SHOWPLAN_XML

# Returns
Таблиця з детальною інформацією про plan:
- stmtId INT - ID Statement в плані
- stmtType NVARCHAR(50) - Тип statement (SELECT, INSERT, UPDATE, DELETE тощо)
- stmtText NVARCHAR(MAX) - Текст SQL statement
- stmtCost FLOAT - Загальна вартість statement
- stmtEstRows FLOAT - Оціночна кількість рядків
- dop INT - Degree of Parallelism
- cachedPlanSizeKb INT - Розмір кешованого плану в KB
- compileTimeMs INT - Час компіляції в мілісекундах
- compileCpuMs INT - CPU час компіляції в мілісекундах
- compileMemoryKb INT - Пам'ять для компіляції в KB
- serialRequiredMemoryKb INT - Необхідна пам'ять для serial виконання
- serialDesiredMemoryKb INT - Бажана пам'ять для serial виконання
- requiredMemoryKb INT - Необхідна пам'ять
- desiredMemoryKb INT - Бажана пам'ять
- requestedMemoryKb INT - Запитана пам'ять
- grantedMemoryKb INT - Надана пам'ять
- maxUsedMemoryKb INT - Максимально використана пам'ять
- grantWaitTimeMs INT - Час очікування memory grant
- elapsedTimeMs BIGINT - Загальний час виконання
- cpuTimeMs BIGINT - CPU час виконання
- optmLevel NVARCHAR(50) - Рівень оптимізації (FULL, TRIVIAL тощо)
- optmAbortReason NVARCHAR(100) - Причина раннього завершення оптимізації
- ceModelVersion INT - Версія моделі Cardinality Estimation
- queryHash NVARCHAR(20) - Query Hash
- queryPlanHash NVARCHAR(20) - Query Plan Hash
- memoryGrantUsedPct FLOAT - Відсоток використаної memory grant
- hasSpill BIT - Індикатор spill to tempdb
- hasWarnings BIT - Індикатор наявності попереджень
- hasMissingIndexes BIT - Індикатор наявності рекомендацій по індексах

# Usage
-- Аналіз actual execution plan з DMV
SELECT p.*
FROM sys.dm_exec_cached_plans cp (NOLOCK)
    CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
    CROSS APPLY util.planSummary(qp.query_plan) p
WHERE p.hasSpill = 1 OR p.hasWarnings = 1;

-- Аналіз конкретного плану за query_hash
DECLARE @queryHash NVARCHAR(20) = '0x1234567890ABCDEF';
SELECT p.*
FROM sys.dm_exec_cached_plans cp (NOLOCK)
    CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
    CROSS APPLY util.planSummary(qp.query_plan) p
WHERE p.queryHash = @queryHash;

-- Пошук планів з неефективним використанням memory grant
SELECT 
    p.stmtText,
    p.grantedMemoryKb,
    p.maxUsedMemoryKb,
    p.memoryGrantUsedPct,
    p.hasSpill
FROM sys.dm_exec_cached_plans cp (NOLOCK)
    CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
    CROSS APPLY util.planSummary(qp.query_plan) p
WHERE p.memoryGrantUsedPct < 50 
    AND p.grantedMemoryKb > 10240
ORDER BY p.grantedMemoryKb DESC;

-- Аналіз estimated plan отриманого через SET SHOWPLAN_XML
DECLARE @plan XML;
-- Тут буде ваш XML plan
SELECT * FROM util.planSummary(@plan);
*/
CREATE OR ALTER FUNCTION util.planSummary(@plan XML)
RETURNS TABLE
AS RETURN (
    WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
    SELECT
        -- Statement info
        Stmt.value('@StatementId', 'int') stmtId,
        Stmt.value('@StatementType', 'nvarchar(50)') stmtType,
        Stmt.value('@StatementText', 'nvarchar(max)') stmtText,
        Stmt.value('@StatementSubTreeCost', 'float') stmtCost,
        Stmt.value('@StatementEstRows', 'float') stmtEstRows,
        
        -- Query Plan info
        QP.value('@DegreeOfParallelism', 'int') dop,
        QP.value('@CachedPlanSize', 'int') cachedPlanSizeKb,
        QP.value('@CompileTime', 'int') compileTimeMs,
        QP.value('@CompileCPU', 'int') compileCpuMs,
        QP.value('@CompileMemory', 'int') compileMemoryKb,
        
        -- Memory Grant
        MG.value('@SerialRequiredMemory', 'int') serialRequiredMemoryKb,
        MG.value('@SerialDesiredMemory', 'int') serialDesiredMemoryKb,
        MG.value('@RequiredMemory', 'int') requiredMemoryKb,
        MG.value('@DesiredMemory', 'int') desiredMemoryKb,
        MG.value('@RequestedMemory', 'int') requestedMemoryKb,
        MG.value('@GrantedMemory', 'int') grantedMemoryKb,
        MG.value('@MaxUsedMemory', 'int') maxUsedMemoryKb,
        MG.value('@GrantWaitTime', 'int') grantWaitTimeMs,
        
        -- Query Time Stats
        QT.value('@ElapsedTime', 'bigint') elapsedTimeMs,
        QT.value('@CpuTime', 'bigint') cpuTimeMs,
        
        -- Optimizer info
        Stmt.value('@StatementOptmLevel', 'nvarchar(50)') optmLevel,
        Stmt.value('@StatementOptmEarlyAbortReason', 'nvarchar(100)') optmAbortReason,
        Stmt.value('@CardinalityEstimationModelVersion', 'int') ceModelVersion,
        Stmt.value('@QueryHash', 'nvarchar(20)') queryHash,
        Stmt.value('@QueryPlanHash', 'nvarchar(20)') queryPlanHash,
        
        -- Memory grant efficiency
        CASE 
            WHEN MG.value('@GrantedMemory', 'int') > 0 
            THEN CAST(MG.value('@MaxUsedMemory', 'int') AS FLOAT) / MG.value('@GrantedMemory', 'int') * 100
            ELSE NULL 
        END memoryGrantUsedPct,
        
        -- Spill detection
        CASE 
            WHEN EXISTS(SELECT 1 FROM Stmt.nodes('.//Warnings/SpillToTempDb') W(X))
            THEN 1 
            ELSE 0 
        END hasSpill,
        
        -- Warning detection
        CASE 
            WHEN EXISTS(SELECT 1 FROM Stmt.nodes('.//Warnings') W(X))
            THEN 1 
            ELSE 0 
        END hasWarnings,
        
        -- Missing index detection
        CASE 
            WHEN EXISTS(SELECT 1 FROM @plan.nodes('//MissingIndexes') MI(X))
            THEN 1 
            ELSE 0 
        END hasMissingIndexes

    FROM @plan.nodes('//StmtSimple') St(Stmt)
        CROSS APPLY Stmt.nodes('./QueryPlan') Q(QP)
        OUTER APPLY QP.nodes('./MemoryGrantInfo') M(MG)
        OUTER APPLY QP.nodes('./QueryTimeStats') T(QT)
);
GO
