# Naming Convention
---

### **Функціїї (Functions)**


** Паттерн `{category}{Action}{Entity}`:**
```sql
- metadataGetAnyId
- metadataGetAnyName
- metadataGetCertificateName
- metadataGetColumnId
- metadataGetColumnName
- metadataGetObjectName
- indexesGetConventionNames
- indexesGetScript
- indexesGetMissing
```
 

---

### **Процедури (Procedures)**

** Паттерн `{entity}Set{Property}`:**
```sql
- metadataSetColumnDescription
- metadataSetFunctionDescription
- metadataSetProcedureDescription
- metadataSetTableDescription
- indexesSetConventionNames
```

** спеціальні:**
```sql
- errorHandler
- help
- xeCopyModulesToTable
```
 

---

### **Параметри, змінні, колонки**

** Параметри:**
```sql
@object NVARCHAR(128) = NULL     -- для об'єктів
@objectId INT = NULL             -- для ID об'єктів
@index NVARCHAR(128) = NULL      -- для індексів
@table NVARCHAR(128) = NULL      -- для таблиць
```

** Змінні:**
```sql
@schemaName NVARCHAR(128)       
@functionName NVARCHAR(128)
@procedureName NVARCHAR(128)
```

** Колонки :**
```sql
objectId INT                     -- camelCase
schemaName NVARCHAR(128)        -- camelCase
columnName NVARCHAR(128)        -- camelCase
```


---

### **індекси (Convention Names)**

 
```sql
PK_{TableName}_{KeyColumns}     -- Primary Key
CI_{KeyColumns}                 -- Clustered Index
IX_{KeyColumns}                 -- Non-clustered Index
CCSI                           -- Clustered Columnstore
CS_{KeyColumns}                -- Columnstore
```

**Суфікси:**
```sql
_INC    -- має included колонки
_FLT    -- має filter
_UQ     -- unique
_P      -- partitioned
_D      -- descending sort (в колонках)
```

---
