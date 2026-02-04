# SQL Trainer (Flask + SQLite)

Мини-сайт-тренажёр по SQL: список задач → страница задачи → ввод SQL → выполнение в SQLite → результат + проверка.

## Запуск (Windows)

```cmd
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

Открой: http://127.0.0.1:5000/

## Запуск (macOS/Linux)

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

## Как устроено

- `data/app.db` — каталог задач (создаётся автоматически из `schema.sql` при первом запуске)- `data/datasets/task_<id>.db` — отдельная база данных для каждой задачи
  - создаётся автоматически при первом открытии задачи

## Проверка решения

- названия колонок сравниваются строго (без учёта регистра)
- данные сравниваются в зависимости от `check_mode` (у нас сейчас везде `unordered`)

## Фильтр по сложности

На главной странице доступен фильтр `Easy / Medium / Hard / Advanced`.
Технически это query-параметр: `/?level=Easy`.

## Добавление новой задачи

1) Открой `schema.sql`
2) Добавь новый `INSERT INTO tasks (...) VALUES (...)`
3) Удали `data/app.db` (чтобы пересоздалась) или вручную обнови БД
