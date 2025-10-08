# Документація pure-utils

Ця директорія містить повну документацію для проєкту pure-utils.

## Структура

```
docs/
├── index.md                    # Головна сторінка
├── getting-started.md          # Початок роботи
├── architecture.md             # Архітектура системи
├── examples.md                 # Практичні приклади
├── faq.md                      # Часті питання
├── scripts.md                  # PowerShell скрипти
├── config.md                   # Конфігурація
├── coding-style.md             # Стиль коду
├── modules/                    # Документація модулів
│   ├── util.md                 # Основна бібліотека
│   ├── mcp.md                  # MCP адаптери
│   ├── PureSqlsMcp.md          # PureSqlsMcp сервер
│   ├── PlanSqlsMcp.md          # PlanSqlsMcp сервер
│   ├── Security.md             # Безпека
│   └── XESessions.md           # Extended Events
└── stylesheets/
    └── extra.css               # Кастомні стилі
```

## Локальний перегляд

### Встановлення MkDocs

```bash
pip install mkdocs-material
pip install mkdocs-minify-plugin
pip install pymdown-extensions
```

### Запуск dev сервера

```bash
mkdocs serve
```

Документація буде доступна на: http://localhost:8000

### Збірка статичного сайту

```bash
mkdocs build
```

Результат буде у директорії `site/`

## Публікація

Документація автоматично публікується на GitHub Pages через GitHub Actions при push до `main` гілки.

URL: https://sql-monk.github.io/pure-utils/

## Внесення змін

1. Відредагуйте відповідний `.md` файл
2. Перевірте зміни локально через `mkdocs serve`
3. Commit та push до репозиторію
4. GitHub Actions автоматично оновить сайт

## Конвенції

- Використовуйте українську мову для документації
- Приклади коду - англійською (T-SQL, PowerShell, JSON)
- Додавайте приклади для кожної функції
- Включайте внутрішні посилання між розділами
- Структуровані заголовки (H2, H3) для навігації

## Стиль написання

- **Заголовок H1**: Назва розділу
- **Заголовок H2**: Основні секції
- **Заголовок H3**: Підсекції
- **Code blocks**: Використовуйте ```sql, ```powershell, ```json
- **Приклади**: Завжди з коментарями та результатами
- **Посилання**: Відносні шляхи (наприклад, `[FAQ](faq.md)`)

## Підтримка

Для питань та пропозицій створіть issue на GitHub.
