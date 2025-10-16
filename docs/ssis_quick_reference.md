# Швидкий довідник SSIS функцій

## 📦 Пакети

```sql
-- Всі пакети
SELECT * FROM util.ssisGetPackages(NULL, NULL, NULL);

-- Конкретна папка
SELECT * FROM util.ssisGetPackages('ETL_Production', NULL, NULL);
```

## 🔗 Підключення

```sql
-- Всі рядки підключення
SELECT * FROM util.ssisGetConnectionStrings(NULL, NULL, NULL);

-- Пошук по серверу
SELECT * FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
WHERE ConnectionString LIKE '%ServerName%';
```

## ▶️ Виконання

```sql
-- Останні 24 години
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, 24);

-- Невдалі (Status=4)
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, 4, 168);

-- Успішні (Status=7)
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, 7, 24);
```

## ❌ Помилки

```sql
-- Всі помилки за добу
SELECT * FROM util.ssisGetExecutionErrors(NULL, NULL, NULL, NULL, 24);

-- Топ помилок
SELECT LEFT(Message, 100), COUNT(*)
FROM util.ssisGetExecutionErrors(NULL, NULL, NULL, NULL, 168)
GROUP BY LEFT(Message, 100)
ORDER BY COUNT(*) DESC;
```

## 📊 Статистика

```sql
-- Загальна статистика
SELECT * FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30);

-- Проблемні пакети
SELECT * FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
WHERE SuccessRate < 90;

-- Найповільніші
SELECT TOP 10 * FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
ORDER BY AvgDurationMinutes DESC;
```

## 📋 Таблиці

```sql
-- Які пакети наповнюють таблицю
SELECT * FROM util.ssisGetPackagesByDestinationTable('FactSales', 'dbo', 30);

-- Всі Fact таблиці
SELECT * FROM util.ssisGetPackagesByDestinationTable(NULL, NULL, 30)
WHERE DestinationTable LIKE '%Fact%';
```

## 🌊 Потоки даних

```sql
-- Аналіз потоків
SELECT * FROM util.ssisGetDataFlows(NULL, NULL, NULL, 7);

-- По компонентах
SELECT ComponentType, SUM(RowsRead), SUM(RowsWritten)
FROM util.ssisGetDataFlows(NULL, NULL, NULL, 7)
GROUP BY ComponentType;
```

## 💬 Повідомлення

```sql
-- Всі типи
SELECT * FROM util.ssisGetEventMessages(NULL, NULL, NULL, NULL, NULL, 24);

-- Тільки помилки (120)
SELECT * FROM util.ssisGetEventMessages(NULL, NULL, NULL, NULL, 120, 24);

-- Попередження (110)
SELECT * FROM util.ssisGetEventMessages(NULL, NULL, NULL, NULL, 110, 24);

-- Інформаційні (70)
SELECT * FROM util.ssisGetEventMessages(NULL, NULL, NULL, NULL, 70, 24);
```

## ⚙️ Параметри

```sql
-- Всі параметри
SELECT * FROM util.ssisGetExecutionParameters(NULL, NULL, NULL, NULL, 24);

-- Конкретне виконання
SELECT * FROM util.ssisGetExecutionParameters(NULL, NULL, NULL, 12345, NULL);
```

## 🔍 Детальний аналіз

```sql
-- Останнє виконання
EXEC util.ssisAnalyzeLastExecution 'Folder', 'Project', 'Package', NULL;

-- Конкретне виконання
EXEC util.ssisAnalyzeLastExecution 'Folder', 'Project', 'Package', 12345;
```

## 📈 Моніторинг

```sql
-- Загальний моніторинг
SELECT * FROM util.viewSsisPackageMonitoring
ORDER BY HealthStatus DESC, PackageName;

-- Критичні проблеми
SELECT * FROM util.viewSsisPackageMonitoring
WHERE HealthStatus = 'Critical';

-- Попередження
SELECT * FROM util.viewSsisPackageMonitoring
WHERE HealthStatus = 'Warning';
```

## 🎯 Типові запити

### Моніторинг здоров'я
```sql
SELECT PackageName, SuccessRate, FailedExecutions, LastFailureTime
FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 7)
WHERE SuccessRate < 100
ORDER BY SuccessRate;
```

### Пошук причин помилки
```sql
-- Останні помилки пакета
SELECT TOP 5 MessageTime, Message, PackagePath
FROM util.ssisGetExecutionErrors(NULL, NULL, 'PackageName', NULL, 168)
ORDER BY MessageTime DESC;

-- Детальний аналіз
EXEC util.ssisAnalyzeLastExecution 'Folder', 'Project', 'PackageName', NULL;
```

### Аудит підключень
```sql
SELECT ProjectName, ConnectionManagerName, 
       CASE WHEN ConnectionString LIKE '%Password%' THEN '[SECURED]' 
            ELSE ConnectionString 
       END ConnectionInfo
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
ORDER BY ProjectName;
```

### Продуктивність
```sql
SELECT PackageName, AvgDurationMinutes, MaxDurationMinutes,
       MaxDurationMinutes - AvgDurationMinutes DurationDeviation
FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
WHERE AvgDurationMinutes > 5
ORDER BY DurationDeviation DESC;
```

### Відстеження завантажень
```sql
SELECT DestinationTable, 
       COUNT(DISTINCT PackageName) PackageCount,
       SUM(TotalRows) TotalRowsProcessed,
       MAX(LastExecutionTime) LastLoad
FROM util.ssisGetPackagesByDestinationTable(NULL, NULL, 30)
GROUP BY DestinationTable
ORDER BY TotalRowsProcessed DESC;
```

## 🔢 Коди статусів

| Код | Статус |
|-----|--------|
| 1 | Created |
| 2 | Running |
| 3 | Canceled |
| 4 | Failed |
| 5 | Pending |
| 6 | Ended unexpectedly |
| 7 | Succeeded |
| 8 | Stopping |
| 9 | Completed |

## 📝 Типи повідомлень

| Код | Тип |
|-----|-----|
| 70 | Information |
| 110 | Warning |
| 120 | Error |
| 130 | TaskFailed |
