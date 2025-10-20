# PuPy - Інструкція з розгортання

## Передумови

1. **Python 3.10+** встановлено на системі
2. **SQL Server** доступний і працює
3. **Доступ до БД** з правами на створення схеми та об'єктів

## Крок 1: Розгортання SQL об'єктів

### 1.1 Створення схеми pupy

```sql
-- Виконати на цільовій БД
USE [YourDatabase];
GO

-- Створити схему pupy
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'pupy')
BEGIN
    EXEC('CREATE SCHEMA pupy');
END
GO
```

Або використати готовий скрипт:
```powershell
# З директорії pure-utils
sqlcmd -S localhost -d YourDatabase -E -i Security/pupy.sql
```

### 1.2 Створення функцій

```powershell
# Створити всі table-valued functions
sqlcmd -S localhost -d YourDatabase -E -i pupy/Functions/databasesList.sql
sqlcmd -S localhost -d YourDatabase -E -i pupy/Functions/tablesList.sql
sqlcmd -S localhost -d YourDatabase -E -i pupy/Functions/proceduresList.sql

# Створити всі scalar functions
sqlcmd -S localhost -d YourDatabase -E -i pupy/Functions/databasesGet.sql
sqlcmd -S localhost -d YourDatabase -E -i pupy/Functions/tablesGet.sql
```

### 1.3 Створення процедур

```powershell
# Створити всі stored procedures
sqlcmd -S localhost -d YourDatabase -E -i pupy/Procedures/objectReferences.sql
sqlcmd -S localhost -d YourDatabase -E -i pupy/Procedures/scriptTable.sql
```

### 1.4 Автоматичне розгортання (PowerShell)

```powershell
# Створити скрипт deployPupy.ps1
$server = "localhost"
$database = "YourDatabase"
$auth = "-E"  # або "-U sa -P password" для SQL Auth

# Схема
sqlcmd -S $server -d $database $auth -i Security/pupy.sql

# Functions
Get-ChildItem -Path "pupy/Functions/*.sql" | ForEach-Object {
    Write-Host "Deploying $($_.Name)..."
    sqlcmd -S $server -d $database $auth -i $_.FullName
}

# Procedures
Get-ChildItem -Path "pupy/Procedures/*.sql" | ForEach-Object {
    Write-Host "Deploying $($_.Name)..."
    sqlcmd -S $server -d $database $auth -i $_.FullName
}

Write-Host "Deployment completed!"
```

## Крок 2: Встановлення Python залежностей

```bash
# З директорії pure-utils
pip install -r requirements.txt
```

Або створити віртуальне середовище:
```bash
# Створити venv
python -m venv .venv

# Активувати (Windows)
.venv\Scripts\activate

# Активувати (Linux/Mac)
source .venv/bin/activate

# Встановити залежності
pip install -r requirements.txt
```

## Крок 3: Запуск API сервера

### 3.1 Windows Authentication

```bash
python PuPy/main.py --server "localhost" --database "YourDatabase"
```

### 3.2 SQL Authentication

```bash
python PuPy/main.py --server "192.168.1.10" --user "sa" --database "YourDatabase"
# Система запитає пароль
```

### 3.3 Кастомні параметри

```bash
python PuPy/main.py \
    --server "myserver.domain.com" \
    --port 1433 \
    --database "MyDB" \
    --user "api_user" \
    --host "0.0.0.0" \
    --api-port 8000
```

## Крок 4: Перевірка роботи

### 4.1 Базова перевірка

Відкрити в браузері:
```
http://localhost:8000/
```

### 4.2 Swagger документація

```
http://localhost:8000/docs
```

### 4.3 Тестування endpoints

```bash
# Використати test_api.py
python PuPy/test_api.py http://localhost:8000
```

### 4.4 Ручне тестування з curl

```bash
# GET request - databases list
curl http://localhost:8000/databases/list

# GET request with parameters - database details
curl "http://localhost:8000/databases/get?databaseName=msdb"

# POST request - object references
curl -X POST "http://localhost:8000/pupy/objectReferences?object=dbo.MyTable"
```

## Крок 5: Production deployment

### 5.1 Systemd Service (Linux)

Створити файл `/etc/systemd/system/pupy-api.service`:

```ini
[Unit]
Description=PuPy FastAPI REST API
After=network.target

[Service]
Type=simple
User=api_user
WorkingDirectory=/opt/pure-utils
Environment="PATH=/opt/pure-utils/.venv/bin"
ExecStart=/opt/pure-utils/.venv/bin/python PuPy/main.py --server localhost --database MyDB
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Запустити сервіс:
```bash
sudo systemctl daemon-reload
sudo systemctl enable pupy-api
sudo systemctl start pupy-api
sudo systemctl status pupy-api
```

### 5.2 Windows Service

Використати `nssm` (Non-Sucking Service Manager):

```powershell
# Завантажити nssm з https://nssm.cc/download
nssm install PuPyAPI "C:\Python310\python.exe" "C:\pure-utils\PuPy\main.py --server localhost --database MyDB"
nssm start PuPyAPI
```

### 5.3 Docker

Створити `Dockerfile`:

```dockerfile
FROM python:3.10-slim

WORKDIR /app

# Install system dependencies for pymssql
RUN apt-get update && apt-get install -y \
    freetds-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY PuPy/ PuPy/

EXPOSE 8000

CMD ["python", "PuPy/main.py", "--server", "${DB_SERVER}", "--database", "${DB_NAME}", "--user", "${DB_USER}"]
```

Запустити:
```bash
docker build -t pupy-api .
docker run -d -p 8000:8000 \
    -e DB_SERVER=myserver \
    -e DB_NAME=mydb \
    -e DB_USER=sa \
    pupy-api
```

## Troubleshooting

### Проблема: Connection refused

**Рішення:** Перевірити:
- SQL Server працює і доступний
- Firewall дозволяє підключення на порт 1433
- TCP/IP протокол увімкнено в SQL Server Configuration Manager

### Проблема: Login failed

**Рішення:** Перевірити:
- Логін існує в SQL Server
- Логін має права доступу до бази даних
- Mixed Mode authentication увімкнено (для SQL Auth)

### Проблема: Object not found

**Рішення:** Перевірити:
- Схема `pupy` створена
- Всі SQL об'єкти розгорнуті
- Використовується правильна база даних

### Проблема: Import error pymssql

**Рішення:**
```bash
# Windows
pip uninstall pymssql
pip install pymssql --no-cache-dir

# Linux
sudo apt-get install freetds-dev
pip install pymssql
```

## Безпека

1. **Використовувати SSL/TLS** для production
2. **Обмежити доступ** за IP адресою
3. **Створити окремого SQL користувача** з мінімальними правами
4. **Використовувати API Gateway** або reverse proxy (nginx, traefik)
5. **Додати автентифікацію** до FastAPI (JWT, OAuth2)

## Моніторинг

### Логи

```bash
# Журнал виводиться в stdout
python PuPy/main.py --server localhost > /var/log/pupy-api.log 2>&1

# Або використати systemd journal
journalctl -u pupy-api -f
```

### Метрики

Розглянути додавання:
- Prometheus metrics endpoint
- Application Insights / CloudWatch
- ELK Stack для централізованих логів
