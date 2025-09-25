# Code Style
 
---
 
####   **Блочні коментарі (Header)**
```sql
/*
# Description
Детальний опис функціональності українською мовою

# Parameters
@param1 TYPE = DEFAULT - опис параметра українською
@param2 TYPE - опис параметра

# Returns  
Опис того що повертається

# Usage
-- Приклад використання
SELECT * FROM util.functionName('value');
*/
```
 

---
 
####  **CREATE statements**
```sql
CREATE OR ALTER FUNCTION util.functionName(@param TYPE = NULL)
RETURNS TABLE
AS
RETURN(
    -- код тут
);
GO
```

```sql
CREATE OR ALTER PROCEDURE util.procedureName
    @param TYPE = NULL
AS
BEGIN
    -- код тут
END;
GO
```

####  **Параметри з DEFAULT значеннями**
```sql
@object NVARCHAR(128) = NULL
@skipEmpty BIT = 1  
@replaceCRwithLF BIT = 1
@output TINYINT = 1
```

---

### **ПРОЦЕДУРИ - Стилістичні паттерни**

#### **Стандартні налаштування**
```sql
AS
BEGIN
    SET NOCOUNT ON;                              -- завжди в процедурах
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  -- у errorHandler
```

#### **Декларації змінних**
```sql
DECLARE @ErrorNumber INT = ERROR_NUMBER();      -- ініціалізація при декларації
DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
DECLARE @currentValue SQL_VARIANT;              -- без ініціалізації
```

---

###  **CTE (Common Table Expressions)**

#### **Послідовна структура**
```sql
WITH cteRn AS (
    SELECT 
        column1,
        ROW_NUMBER() OVER (ORDER BY column1) rn
    FROM table1
),
cteFiltered AS (
    SELECT * 
    FROM cteRn 
    WHERE rn = 1
)
SELECT * FROM cteFiltered
```


---

### **ПАТТЕРНИ УМОВ та ФІЛЬТРАЦІЇ**

#### objects
```sql
WHERE (@object IS NULL OR column = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
```

##### Indexes, Columns
```sql
WHERE (@columnId IS NULL OR c.coumn_id = @columnId)
```

```sql
WHERE (@index IS NULL OR i.name = @index)
```

#### **конвертація**
```sql
ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object))
```


---

#### **(NOLOCK) для схеми sys**
```sql
FROM sys.indexes i (NOLOCK)
    INNER JOIN sys.tables t (NOLOCK) ON i.object_id = t.object_id
    LEFT JOIN sys.data_spaces ds (NOLOCK) ON i.data_space_id = ds.data_space_id
```

#### **Alias patterns**
```sql
FROM sys.indexes idx         
FROM sys.tables tab
FROM sys.columns cols
FROM util.functionName fn
```

```sql
FROM sys.indexes i
FROM sys.tables t
FROM sys.columns c
FROM util.functionName f
```

---

### **SELECT statements**

#### **Форматування колонок**
```sql
SELECT 
    c.object_id objectId,                    -- без AS
    OBJECT_SCHEMA_NAME(c.object_id) schemaName,
    OBJECT_NAME(c.object_id) objectName,
    c.column_id columnId,
    c.name columnName
```

#### **CASE statements**  
```sql
CASE 
    WHEN condition1 THEN value1
    WHEN condition2 THEN value2  
    ELSE defaultValue
END AS columnName
```

---
 
#### **CONCAT замість +** де це можливо
```sql
CONCAT('PK_', ii.TableName, '_', LEFT(ISNULL(ic.KeyColumns, ''), 100))
```

#### **QUOTENAME для безпеки**
```sql
CONCAT(QUOTENAME(s.name), '.', QUOTENAME(t.name))
```


---

#### **Inline Table Functions**
```sql
CREATE OR ALTER FUNCTION util.functionName(@param TYPE = NULL)
RETURNS TABLE
AS
RETURN(
    SELECT ... 
    FROM ...
    WHERE ...
);
```

#### **Scalar Functions**
```sql
CREATE OR ALTER FUNCTION util.functionName(@param TYPE)
RETURNS TYPE
AS
BEGIN
    RETURN (SELECT ... FROM ... WHERE ...);
END;
```

---


#### **Відступи**
- **4 пробіли** для основних блоків
- **8 пробілів** для вкладених блоків
- **Вирівнювання** за ключовими словами

#### **Перенос рядків**
```sql
SELECT 
    column1,
    column2,
    column3
FROM table1
    INNER JOIN table2 ON condition
WHERE condition1
    AND condition2
    AND condition3
```

---

### **BEST PRACTICES**

1. **Мова**: Документація українською, код англійською
2. **Консистентність**: Однакові паттерни у всіх файлах
3. **Безпечність**: TRY_CONVERT, QUOTENAME, ISNULL
4. **Читабельність**: Коментарі та логічне форматування
5. **Універсальність**: NULL parameters для "всі записи"
6. **Оптимізація**: NOLOCK, ефективні JOIN-и
7. **Стандартизація**: Однакова структура коментарів
8. **Модульність**: Переважно невеликі, сфокусовані функції

---
