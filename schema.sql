-- Schema for app DB (tasks catalog)
CREATE TABLE IF NOT EXISTS tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  short_desc TEXT NOT NULL,
  level TEXT NOT NULL,             -- Easy | Medium | Hard | Advanced
  full_desc TEXT NOT NULL,
  dataset_sql TEXT NOT NULL,
  seed_sql TEXT NOT NULL,
  solution_sql TEXT NOT NULL,
  check_mode TEXT NOT NULL DEFAULT 'unordered' -- unordered | ordered
);

DELETE FROM tasks; -- for easy re-init in pet project

-- TASK 1: Users + Orders (LEFT JOIN + COUNT)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Заказы пользователей',
  'Вывести пользователей и количество их заказов (включая тех, у кого 0).',
  'Easy',
  'Сформируйте запрос, который вернёт список пользователей и число их заказов. В результате должны быть все пользователи, даже если у них нет заказов.

Ожидаемые колонки: name, orders_cnt',
  '
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
  );

  CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    amount INTEGER NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
  );
  ',
  '
  INSERT INTO users (id, name) VALUES
    (1, ''Alice''),
    (2, ''Bob''),
    (3, ''Charlie''),
    (4, ''Diana'');

  INSERT INTO orders (id, user_id, amount, created_at) VALUES
    (1, 1, 100, ''2026-01-10''),
    (2, 1, 50,  ''2026-01-11''),
    (3, 2, 30,  ''2026-01-12'');
  ',
  '
  SELECT
    u.name AS name,
    COUNT(o.id) AS orders_cnt
  FROM users u
  LEFT JOIN orders o ON u.id = o.user_id
  GROUP BY u.id, u.name;
  ',
  'unordered'
);

-- TASK 2: Orders revenue per user (SUM + GROUP BY)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Выручка по пользователям',
  'Посчитать суммарную выручку по каждому пользователю.',
  'Easy',
  'Напишите запрос, который вернёт пользователей и суммарную выручку (total_amount) по их заказам.

Требования:
- Пользователи без заказов тоже должны быть в выдаче (total_amount = 0).

Ожидаемые колонки: name, total_amount',
  '
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
  );

  CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    amount INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
  );
  ',
  '
  INSERT INTO users (id, name) VALUES
    (1, ''Alice''),
    (2, ''Bob''),
    (3, ''Charlie''),
    (4, ''Diana'');

  INSERT INTO orders (id, user_id, amount) VALUES
    (1, 1, 100),
    (2, 1, 50),
    (3, 2, 30),
    (4, 2, 70),
    (5, 4, 25);
  ',
  '
  SELECT
    u.name AS name,
    COALESCE(SUM(o.amount), 0) AS total_amount
  FROM users u
  LEFT JOIN orders o ON u.id = o.user_id
  GROUP BY u.id, u.name;
  ',
  'unordered'
);

-- TASK 3: Products not ordered (NOT EXISTS)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Товары без заказов',
  'Найти товары, которые ни разу не покупали.',
  'Medium',
  'Даны таблицы товаров и строк заказов.
Найдите товары, которые не встречаются ни в одной строке заказа.

Ожидаемые колонки: product_name',
  '
  CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
  );

  CREATE TABLE order_items (
    id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    qty INTEGER NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id)
  );
  ',
  '
  INSERT INTO products (id, name) VALUES
    (1, ''Keyboard''),
    (2, ''Mouse''),
    (3, ''Monitor''),
    (4, ''USB Cable''),
    (5, ''Laptop Stand'');

  INSERT INTO order_items (id, order_id, product_id, qty) VALUES
    (1, 101, 1, 1),
    (2, 101, 2, 2),
    (3, 102, 2, 1),
    (4, 103, 3, 1),
    (5, 103, 1, 1);
  ',
  '
  SELECT
    p.name AS product_name
  FROM products p
  WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    WHERE oi.product_id = p.id
  );
  ',
  'unordered'
);

-- TASK 4: Top category by sales
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Лучшая категория по продажам',
  'Определить категорию с максимальной выручкой.',
  'Medium',
  'Есть товары с категориями и строки заказов.
Найдите категорию, у которой суммарная выручка (qty * price) максимальна.

Ожидаемые колонки: category, revenue',
  '
  CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    price INTEGER NOT NULL
  );

  CREATE TABLE order_items (
    id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    qty INTEGER NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id)
  );
  ',
  '
  INSERT INTO products (id, name, category, price) VALUES
    (1, ''Keyboard'',     ''Peripherals'', 100),
    (2, ''Mouse'',        ''Peripherals'', 50),
    (3, ''Monitor'',      ''Displays'',    300),
    (4, ''USB Cable'',    ''Accessories'', 10),
    (5, ''Laptop Stand'', ''Accessories'', 25);

  INSERT INTO order_items (id, order_id, product_id, qty) VALUES
    (1, 201, 1, 1),
    (2, 201, 2, 2),
    (3, 202, 3, 1),
    (4, 203, 4, 5),
    (5, 203, 5, 2),
    (6, 204, 2, 1);
  ',
  '
  SELECT
    p.category AS category,
    SUM(oi.qty * p.price) AS revenue
  FROM order_items oi
  JOIN products p ON p.id = oi.product_id
  GROUP BY p.category
  ORDER BY revenue DESC, category ASC
  LIMIT 1;
  ',
  'unordered'
);

-- TASK 5: Find only red cars (your task)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Найти все красные машины',
  'Найти только машины красного цвета.',
  'Easy',
  'У вас есть перечень автомобилей различных марок. Необходимо найти все машины красного цвета.

Ожидаемые колонки: car',
  '
  CREATE TABLE cars (
    id INTEGER PRIMARY KEY,
    car_name TEXT NOT NULL,
    color TEXT NOT NULL,
    price INTEGER NOT NULL
  );
  ',
  '
  INSERT INTO cars (id, car_name, color, price) VALUES
    (1, ''Nissan'',     ''Red'',     324000),
    (2, ''BMW'',        ''Yellow'',  1540000),
    (3, ''Audi'',       ''Green'',   2357000),
    (4, ''LADA'',       ''Red'',     1),
    (5, ''Opel'',       ''Black'',   2),
    (6, ''Mitsubishi'', ''Orange'',  100000);
  ',
  '
  SELECT
    car_name AS car
  FROM cars
  WHERE color = ''Red'';
  ',
  'unordered'
);
-- =========================
-- EASY TASKS
-- =========================

INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Пользователи старше 30',
  'Найти всех пользователей старше 30 лет',
  'Easy',
  'Выведите имена пользователей, чей возраст больше 30 лет.
Ожидаемая колонка: name',
  '
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    age INTEGER
  );',
  '
  INSERT INTO users VALUES
  (1, ''Alice'', 25),
  (2, ''Bob'', 35),
  (3, ''Charlie'', 40),
  (4, ''Diana'', 30);',
  '
  SELECT name
  FROM users
  WHERE age > 30;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Все пользователи',
  'Вывести всех пользователей',
  'Easy',
  'Выведите всех пользователей из таблицы users.
Ожидаемые колонки: id, name',
  '
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT
  );',
  '
  INSERT INTO users VALUES
  (1, ''Ann''),
  (2, ''Ben''),
  (3, ''Chris'');',
  '
  SELECT id, name FROM users;',
  'ordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Количество заказов',
  'Посчитать количество заказов',
  'Easy',
  'Подсчитайте общее количество заказов.
Ожидаемая колонка: orders_cnt',
  '
  CREATE TABLE orders (
    id INTEGER PRIMARY KEY
  );',
  '
  INSERT INTO orders VALUES (1),(2),(3),(4);',
  '
  SELECT COUNT(*) AS orders_cnt FROM orders;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Самый дорогой заказ',
  'Найти максимальную сумму заказа',
  'Easy',
  'Найдите максимальную сумму заказа.
Ожидаемая колонка: max_total',
  '
  CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    total INTEGER
  );',
  '
  INSERT INTO orders VALUES
  (1, 50),
  (2, 120),
  (3, 80);',
  '
  SELECT MAX(total) AS max_total FROM orders;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Пользователи без возраста',
  'Найти пользователей с NULL возрастом',
  'Easy',
  'Выведите имена пользователей, у которых не указан возраст.
Ожидаемая колонка: name',
  '
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    age INTEGER
  );',
  '
  INSERT INTO users VALUES
  (1, ''Tom'', NULL),
  (2, ''Jerry'', 20);',
  '
  SELECT name FROM users WHERE age IS NULL;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Топ-2 заказов',
  'Два самых дорогих заказа',
  'Easy',
  'Выведите два самых дорогих заказа по убыванию суммы.
Ожидаемые колонки: id, total',
  '
  CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    total INTEGER
  );',
  '
  INSERT INTO orders VALUES
  (1, 10),
  (2, 300),
  (3, 200);',
  '
  SELECT id, total FROM orders ORDER BY total DESC LIMIT 2;',
  'ordered'
);

-- =========================
-- MEDIUM TASKS
-- =========================

INSERT INTO tasks VALUES (
  NULL,
  'Заказы по пользователям',
  'Количество заказов у каждого пользователя',
  'Medium',
  'Для каждого пользователя посчитайте количество его заказов.
Ожидаемые колонки: name, orders_cnt',
  '
  CREATE TABLE users (id INTEGER, name TEXT);
  CREATE TABLE orders (id INTEGER, user_id INTEGER);',
  '
  INSERT INTO users VALUES (1,''Alice''),(2,''Bob'');
  INSERT INTO orders VALUES (1,1),(2,1),(3,2);',
  '
  SELECT u.name, COUNT(o.id) AS orders_cnt
  FROM users u
  LEFT JOIN orders o ON o.user_id = u.id
  GROUP BY u.id;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Средний чек по статусу',
  'Средняя сумма заказов по статусу',
  'Medium',
  'Посчитайте среднюю сумму заказов для каждого статуса.
Ожидаемые колонки: status, avg_total',
  '
  CREATE TABLE orders (id INTEGER, total INTEGER, status TEXT);',
  '
  INSERT INTO orders VALUES
  (1,100,''done''),
  (2,200,''done''),
  (3,50,''new'');',
  '
  SELECT status, AVG(total) AS avg_total
  FROM orders
  GROUP BY status;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Пользователи без заказов',
  'Найти пользователей без заказов',
  'Medium',
  'Выведите пользователей, у которых нет заказов.
Ожидаемая колонка: name',
  '
  CREATE TABLE users (id INTEGER, name TEXT);
  CREATE TABLE orders (id INTEGER, user_id INTEGER);',
  '
  INSERT INTO users VALUES (1,''A''),(2,''B'');
  INSERT INTO orders VALUES (1,1);',
  '
  SELECT u.name
  FROM users u
  LEFT JOIN orders o ON o.user_id = u.id
  WHERE o.id IS NULL;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Максимальный заказ пользователя',
  'Максимальный заказ для каждого пользователя',
  'Medium',
  'Для каждого пользователя найдите максимальную сумму его заказа.
Ожидаемые колонки: user_id, max_total',
  '
  CREATE TABLE orders (id INTEGER, user_id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES
  (1,1,100),(2,1,300),(3,2,50);',
  '
  SELECT user_id, MAX(total) AS max_total
  FROM orders
  GROUP BY user_id;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Пользователи с >1 заказом',
  'Пользователи с более чем одним заказом',
  'Medium',
  'Выведите пользователей, у которых больше одного заказа.
Ожидаемая колонка: user_id',
  '
  CREATE TABLE orders (id INTEGER, user_id INTEGER);',
  '
  INSERT INTO orders VALUES (1,1),(2,1),(3,2);',
  '
  SELECT user_id
  FROM orders
  GROUP BY user_id
  HAVING COUNT(*) > 1;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Сумма заказов пользователя',
  'Общая сумма заказов по пользователям',
  'Medium',
  'Для каждого пользователя посчитайте сумму его заказов.
Ожидаемые колонки: user_id, total_sum',
  '
  CREATE TABLE orders (id INTEGER, user_id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES
  (1,1,100),(2,1,50),(3,2,70);',
  '
  SELECT user_id, SUM(total) AS total_sum
  FROM orders
  GROUP BY user_id;',
  'unordered'
);

-- =========================
-- HARD TASKS
-- =========================

INSERT INTO tasks VALUES (
  NULL,
  'Самый дорогой заказ каждого пользователя',
  'Найти топ-заказ по пользователю',
  'Hard',
  'Для каждого пользователя найдите его самый дорогой заказ.
Ожидаемые колонки: user_id, max_total',
  '
  CREATE TABLE orders (id INTEGER, user_id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES
  (1,1,100),(2,1,200),(3,2,50);',
  '
  SELECT user_id, MAX(total) AS max_total
  FROM orders
  GROUP BY user_id;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Заказы выше среднего',
  'Заказы выше среднего чека',
  'Hard',
  'Выведите заказы, сумма которых выше средней суммы всех заказов.
Ожидаемые колонки: id, total',
  '
  CREATE TABLE orders (id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES (1,50),(2,150),(3,100);',
  '
  SELECT id, total
  FROM orders
  WHERE total > (SELECT AVG(total) FROM orders);',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Ранг заказов',
  'Ранжировать заказы по сумме',
  'Hard',
  'Пронумеруйте заказы по убыванию суммы.
Ожидаемые колонки: id, rank',
  '
  CREATE TABLE orders (id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES (1,300),(2,100),(3,200);',
  '
  SELECT id,
         RANK() OVER (ORDER BY total DESC) AS rank
  FROM orders;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Заказы выше среднего по пользователю',
  'Коррелированный подзапрос',
  'Hard',
  'Выведите заказы, которые выше среднего заказа своего пользователя.
Ожидаемые колонки: id, total',
  '
  CREATE TABLE orders (id INTEGER, user_id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES
  (1,1,100),(2,1,200),(3,2,50);',
  '
  SELECT o.id, o.total
  FROM orders o
  WHERE o.total >
    (SELECT AVG(total)
     FROM orders
     WHERE user_id = o.user_id);',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Самый активный пользователь',
  'Пользователь с максимальным числом заказов',
  'Hard',
  'Найдите пользователя с максимальным количеством заказов.
Ожидаемая колонка: user_id',
  '
  CREATE TABLE orders (id INTEGER, user_id INTEGER);',
  '
  INSERT INTO orders VALUES
  (1,1),(2,1),(3,2);',
  '
  SELECT user_id
  FROM orders
  GROUP BY user_id
  ORDER BY COUNT(*) DESC
  LIMIT 1;',
  'ordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Медианный заказ',
  'Найти медиану суммы заказов',
  'Hard',
  'Найдите медианную сумму заказов.
Ожидаемая колонка: median_total',
  '
  CREATE TABLE orders (id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES (1,10),(2,30),(3,20);',
  '
  SELECT AVG(total) AS median_total
  FROM (
    SELECT total
    FROM orders
    ORDER BY total
    LIMIT 2 - (SELECT COUNT(*) FROM orders) % 2
    OFFSET (SELECT (COUNT(*) - 1) / 2 FROM orders)
  );',
  'unordered'
);
-- =========================
-- DATASET: SHOP (users / products / orders / order_items)
-- =========================

-- EASY 1: list all users from Amsterdam
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Shop: Users from Amsterdam',
  'Select users who live in Amsterdam.',
  'Easy',
  'Return all users who live in Amsterdam. Expected columns: id, name, city.',
  '
  PRAGMA foreign_keys = ON;

  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    city TEXT NOT NULL,
    created_at TEXT NOT NULL
  );

  CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    price REAL NOT NULL
  );

  CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    status TEXT NOT NULL,
    ordered_at TEXT NOT NULL,
    FOREIGN KEY(user_id) REFERENCES users(id)
  );

  CREATE TABLE order_items (
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    qty INTEGER NOT NULL,
    PRIMARY KEY(order_id, product_id),
    FOREIGN KEY(order_id) REFERENCES orders(id),
    FOREIGN KEY(product_id) REFERENCES products(id)
  );
  ',
  '
  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 20
  )
  INSERT INTO users(id, name, city, created_at)
  SELECT
    n,
    ''User '' || n,
    CASE (n % 5)
      WHEN 0 THEN ''Amsterdam''
      WHEN 1 THEN ''Berlin''
      WHEN 2 THEN ''Paris''
      WHEN 3 THEN ''Warsaw''
      ELSE ''Rome''
    END,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day'')
  FROM seq;

  INSERT INTO products(id, name, category, price) VALUES
    (1,''Laptop'',''Electronics'',999.0),
    (2,''Mouse'',''Electronics'',25.0),
    (3,''Keyboard'',''Electronics'',70.0),
    (4,''Coffee beans'',''Grocery'',12.5),
    (5,''Pasta'',''Grocery'',3.2),
    (6,''T-shirt'',''Clothes'',19.9),
    (7,''Jeans'',''Clothes'',55.0),
    (8,''Book'',''Books'',15.0),
    (9,''Notebook'',''Stationery'',4.5),
    (10,''Pen'',''Stationery'',1.2);

  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 50
  )
  INSERT INTO orders(id, user_id, status, ordered_at)
  SELECT
    n,
    1 + (n % 20),
    CASE (n % 4)
      WHEN 0 THEN ''paid''
      WHEN 1 THEN ''shipped''
      WHEN 2 THEN ''delivered''
      ELSE ''cancelled''
    END,
    date(''2026-01-01'', ''+'' || (n % 31) || '' day'')
  FROM seq;

  WITH RECURSIVE ord(o) AS (
    SELECT 1
    UNION ALL SELECT o+1 FROM ord WHERE o < 50
  ),
  items(k) AS (
    SELECT 0
    UNION ALL SELECT 1
  )
  INSERT INTO order_items(order_id, product_id, qty)
  SELECT
    o AS order_id,
    CASE k
      WHEN 0 THEN 1 + (o % 10)
      ELSE 1 + ((o + 3) % 10)
    END AS product_id,
    CASE k
      WHEN 0 THEN 1 + (o % 3)
      ELSE 1 + ((o + 1) % 2)
    END AS qty
  FROM ord
  CROSS JOIN items;
  ',
  '
  SELECT id, name, city
  FROM users
  WHERE city = ''Amsterdam''
  ORDER BY id;
  ',
  'ordered'
);

-- EASY 2: count all orders
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Shop: Orders count',
  'Count total number of orders.',
  'Easy',
  'Count total number of rows in orders. Expected column: orders_cnt.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, created_at TEXT NOT NULL);
  CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, price REAL NOT NULL);
  CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL, status TEXT NOT NULL, ordered_at TEXT NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id));
  CREATE TABLE order_items (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, qty INTEGER NOT NULL, PRIMARY KEY(order_id, product_id), FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(product_id) REFERENCES products(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO users(id, name, city, created_at)
  SELECT n, ''User '' || n,
    CASE (n % 5) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Berlin'' WHEN 2 THEN ''Paris'' WHEN 3 THEN ''Warsaw'' ELSE ''Rome'' END,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day'')
  FROM seq;

  INSERT INTO products(id, name, category, price) VALUES
    (1,''Laptop'',''Electronics'',999.0),(2,''Mouse'',''Electronics'',25.0),(3,''Keyboard'',''Electronics'',70.0),
    (4,''Coffee beans'',''Grocery'',12.5),(5,''Pasta'',''Grocery'',3.2),(6,''T-shirt'',''Clothes'',19.9),
    (7,''Jeans'',''Clothes'',55.0),(8,''Book'',''Books'',15.0),(9,''Notebook'',''Stationery'',4.5),(10,''Pen'',''Stationery'',1.2);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, user_id, status, ordered_at)
  SELECT n, 1 + (n % 20),
    CASE (n % 4) WHEN 0 THEN ''paid'' WHEN 1 THEN ''shipped'' WHEN 2 THEN ''delivered'' ELSE ''cancelled'' END,
    date(''2026-01-01'', ''+'' || (n % 31) || '' day'')
  FROM seq;

  WITH RECURSIVE ord(o) AS (SELECT 1 UNION ALL SELECT o+1 FROM ord WHERE o < 50),
  items(k) AS (SELECT 0 UNION ALL SELECT 1)
  INSERT INTO order_items(order_id, product_id, qty)
  SELECT
    o,
    CASE k WHEN 0 THEN 1 + (o % 10) ELSE 1 + ((o + 3) % 10) END,
    CASE k WHEN 0 THEN 1 + (o % 3) ELSE 1 + ((o + 1) % 2) END
  FROM ord CROSS JOIN items;
  ',
  '
  SELECT COUNT(*) AS orders_cnt
  FROM orders;
  ',
  'unordered'
);

-- EASY 3: list products cheaper than 10
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Shop: Cheap products',
  'Find products with price < 10.',
  'Easy',
  'Return all products with price < 10. Expected columns: id, name, price.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, created_at TEXT NOT NULL);
  CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, price REAL NOT NULL);
  CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL, status TEXT NOT NULL, ordered_at TEXT NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id));
  CREATE TABLE order_items (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, qty INTEGER NOT NULL, PRIMARY KEY(order_id, product_id), FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(product_id) REFERENCES products(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO users(id, name, city, created_at)
  SELECT n, ''User '' || n,
    CASE (n % 5) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Berlin'' WHEN 2 THEN ''Paris'' WHEN 3 THEN ''Warsaw'' ELSE ''Rome'' END,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day'')
  FROM seq;

  INSERT INTO products(id, name, category, price) VALUES
    (1,''Laptop'',''Electronics'',999.0),(2,''Mouse'',''Electronics'',25.0),(3,''Keyboard'',''Electronics'',70.0),
    (4,''Coffee beans'',''Grocery'',12.5),(5,''Pasta'',''Grocery'',3.2),(6,''T-shirt'',''Clothes'',19.9),
    (7,''Jeans'',''Clothes'',55.0),(8,''Book'',''Books'',15.0),(9,''Notebook'',''Stationery'',4.5),(10,''Pen'',''Stationery'',1.2);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, user_id, status, ordered_at)
  SELECT n, 1 + (n % 20),
    CASE (n % 4) WHEN 0 THEN ''paid'' WHEN 1 THEN ''shipped'' WHEN 2 THEN ''delivered'' ELSE ''cancelled'' END,
    date(''2026-01-01'', ''+'' || (n % 31) || '' day'')
  FROM seq;

  WITH RECURSIVE ord(o) AS (SELECT 1 UNION ALL SELECT o+1 FROM ord WHERE o < 50),
  items(k) AS (SELECT 0 UNION ALL SELECT 1)
  INSERT INTO order_items(order_id, product_id, qty)
  SELECT
    o,
    CASE k WHEN 0 THEN 1 + (o % 10) ELSE 1 + ((o + 3) % 10) END,
    CASE k WHEN 0 THEN 1 + (o % 3) ELSE 1 + ((o + 1) % 2) END
  FROM ord CROSS JOIN items;
  ',
  '
  SELECT id, name, price
  FROM products
  WHERE price < 10
  ORDER BY price ASC, id ASC;
  ',
  'ordered'
);

-- MEDIUM 1: revenue by category
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Shop: Revenue by category',
  'Compute revenue per category (qty * price).',
  'Medium',
  'Compute revenue per product category: SUM(qty * price). Expected columns: category, revenue.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, created_at TEXT NOT NULL);
  CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, price REAL NOT NULL);
  CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL, status TEXT NOT NULL, ordered_at TEXT NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id));
  CREATE TABLE order_items (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, qty INTEGER NOT NULL, PRIMARY KEY(order_id, product_id), FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(product_id) REFERENCES products(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO users(id, name, city, created_at)
  SELECT n, ''User '' || n,
    CASE (n % 5) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Berlin'' WHEN 2 THEN ''Paris'' WHEN 3 THEN ''Warsaw'' ELSE ''Rome'' END,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day'')
  FROM seq;

  INSERT INTO products(id, name, category, price) VALUES
    (1,''Laptop'',''Electronics'',999.0),(2,''Mouse'',''Electronics'',25.0),(3,''Keyboard'',''Electronics'',70.0),
    (4,''Coffee beans'',''Grocery'',12.5),(5,''Pasta'',''Grocery'',3.2),(6,''T-shirt'',''Clothes'',19.9),
    (7,''Jeans'',''Clothes'',55.0),(8,''Book'',''Books'',15.0),(9,''Notebook'',''Stationery'',4.5),(10,''Pen'',''Stationery'',1.2);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, user_id, status, ordered_at)
  SELECT n, 1 + (n % 20),
    CASE (n % 4) WHEN 0 THEN ''paid'' WHEN 1 THEN ''shipped'' WHEN 2 THEN ''delivered'' ELSE ''cancelled'' END,
    date(''2026-01-01'', ''+'' || (n % 31) || '' day'')
  FROM seq;

  WITH RECURSIVE ord(o) AS (SELECT 1 UNION ALL SELECT o+1 FROM ord WHERE o < 50),
  items(k) AS (SELECT 0 UNION ALL SELECT 1)
  INSERT INTO order_items(order_id, product_id, qty)
  SELECT
    o,
    CASE k WHEN 0 THEN 1 + (o % 10) ELSE 1 + ((o + 3) % 10) END,
    CASE k WHEN 0 THEN 1 + (o % 3) ELSE 1 + ((o + 1) % 2) END
  FROM ord CROSS JOIN items;
  ',
  '
  SELECT p.category AS category,
         SUM(oi.qty * p.price) AS revenue
  FROM order_items oi
  JOIN products p ON p.id = oi.product_id
  GROUP BY p.category
  ORDER BY revenue DESC, category ASC;
  ',
  'ordered'
);

-- MEDIUM 2: users with >= 3 orders
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Shop: Users with 3+ orders',
  'Find users who made at least 3 orders.',
  'Medium',
  'Return users who have at least 3 orders. Expected columns: user_id, name, orders_cnt.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, created_at TEXT NOT NULL);
  CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, price REAL NOT NULL);
  CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL, status TEXT NOT NULL, ordered_at TEXT NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id));
  CREATE TABLE order_items (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, qty INTEGER NOT NULL, PRIMARY KEY(order_id, product_id), FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(product_id) REFERENCES products(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO users(id, name, city, created_at)
  SELECT n, ''User '' || n,
    CASE (n % 5) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Berlin'' WHEN 2 THEN ''Paris'' WHEN 3 THEN ''Warsaw'' ELSE ''Rome'' END,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day'')
  FROM seq;

  INSERT INTO products(id, name, category, price) VALUES
    (1,''Laptop'',''Electronics'',999.0),(2,''Mouse'',''Electronics'',25.0),(3,''Keyboard'',''Electronics'',70.0),
    (4,''Coffee beans'',''Grocery'',12.5),(5,''Pasta'',''Grocery'',3.2),(6,''T-shirt'',''Clothes'',19.9),
    (7,''Jeans'',''Clothes'',55.0),(8,''Book'',''Books'',15.0),(9,''Notebook'',''Stationery'',4.5),(10,''Pen'',''Stationery'',1.2);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, user_id, status, ordered_at)
  SELECT n, 1 + (n % 20),
    CASE (n % 4) WHEN 0 THEN ''paid'' WHEN 1 THEN ''shipped'' WHEN 2 THEN ''delivered'' ELSE ''cancelled'' END,
    date(''2026-01-01'', ''+'' || (n % 31) || '' day'')
  FROM seq;

  WITH RECURSIVE ord(o) AS (SELECT 1 UNION ALL SELECT o+1 FROM ord WHERE o < 50),
  items(k) AS (SELECT 0 UNION ALL SELECT 1)
  INSERT INTO order_items(order_id, product_id, qty)
  SELECT
    o,
    CASE k WHEN 0 THEN 1 + (o % 10) ELSE 1 + ((o + 3) % 10) END,
    CASE k WHEN 0 THEN 1 + (o % 3) ELSE 1 + ((o + 1) % 2) END
  FROM ord CROSS JOIN items;
  ',
  '
  SELECT u.id AS user_id,
         u.name AS name,
         COUNT(o.id) AS orders_cnt
  FROM users u
  JOIN orders o ON o.user_id = u.id
  GROUP BY u.id, u.name
  HAVING COUNT(o.id) >= 3
  ORDER BY orders_cnt DESC, user_id ASC;
  ',
  'ordered'
);

-- MEDIUM 3: delivered orders per day
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Shop: Delivered orders per day',
  'Count delivered orders per date.',
  'Medium',
  'For each ordered_at date, count delivered orders (status = delivered). Expected columns: ordered_at, delivered_cnt.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, created_at TEXT NOT NULL);
  CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, price REAL NOT NULL);
  CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL, status TEXT NOT NULL, ordered_at TEXT NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id));
  CREATE TABLE order_items (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, qty INTEGER NOT NULL, PRIMARY KEY(order_id, product_id), FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(product_id) REFERENCES products(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO users(id, name, city, created_at)
  SELECT n, ''User '' || n,
    CASE (n % 5) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Berlin'' WHEN 2 THEN ''Paris'' WHEN 3 THEN ''Warsaw'' ELSE ''Rome'' END,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day'')
  FROM seq;

  INSERT INTO products(id, name, category, price) VALUES
    (1,''Laptop'',''Electronics'',999.0),(2,''Mouse'',''Electronics'',25.0),(3,''Keyboard'',''Electronics'',70.0),
    (4,''Coffee beans'',''Grocery'',12.5),(5,''Pasta'',''Grocery'',3.2),(6,''T-shirt'',''Clothes'',19.9),
    (7,''Jeans'',''Clothes'',55.0),(8,''Book'',''Books'',15.0),(9,''Notebook'',''Stationery'',4.5),(10,''Pen'',''Stationery'',1.2);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, user_id, status, ordered_at)
  SELECT n, 1 + (n % 20),
    CASE (n % 4) WHEN 0 THEN ''paid'' WHEN 1 THEN ''shipped'' WHEN 2 THEN ''delivered'' ELSE ''cancelled'' END,
    date(''2026-01-01'', ''+'' || (n % 31) || '' day'')
  FROM seq;

  WITH RECURSIVE ord(o) AS (SELECT 1 UNION ALL SELECT o+1 FROM ord WHERE o < 50),
  items(k) AS (SELECT 0 UNION ALL SELECT 1)
  INSERT INTO order_items(order_id, product_id, qty)
  SELECT
    o,
    CASE k WHEN 0 THEN 1 + (o % 10) ELSE 1 + ((o + 3) % 10) END,
    CASE k WHEN 0 THEN 1 + (o % 3) ELSE 1 + ((o + 1) % 2) END
  FROM ord CROSS JOIN items;
  ',
  '
  SELECT ordered_at,
         COUNT(*) AS delivered_cnt
  FROM orders
  WHERE status = ''delivered''
  GROUP BY ordered_at
  ORDER BY ordered_at;
  ',
  'ordered'
);

-- HARD 1: top users by revenue (sum qty*price) include user name
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Shop: Top users by revenue',
  'Compute revenue per user and sort descending.',
  'Hard',
  'Compute total revenue per user: SUM(qty * price) across all their orders. Return all users with revenue (0 if no items). Expected columns: user_id, name, revenue.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, created_at TEXT NOT NULL);
  CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, price REAL NOT NULL);
  CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL, status TEXT NOT NULL, ordered_at TEXT NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id));
  CREATE TABLE order_items (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, qty INTEGER NOT NULL, PRIMARY KEY(order_id, product_id), FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(product_id) REFERENCES products(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO users(id, name, city, created_at)
  SELECT n, ''User '' || n,
    CASE (n % 5) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Berlin'' WHEN 2 THEN ''Paris'' WHEN 3 THEN ''Warsaw'' ELSE ''Rome'' END,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day'')
  FROM seq;

  INSERT INTO products(id, name, category, price) VALUES
    (1,''Laptop'',''Electronics'',999.0),(2,''Mouse'',''Electronics'',25.0),(3,''Keyboard'',''Electronics'',70.0),
    (4,''Coffee beans'',''Grocery'',12.5),(5,''Pasta'',''Grocery'',3.2),(6,''T-shirt'',''Clothes'',19.9),
    (7,''Jeans'',''Clothes'',55.0),(8,''Book'',''Books'',15.0),(9,''Notebook'',''Stationery'',4.5),(10,''Pen'',''Stationery'',1.2);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, user_id, status, ordered_at)
  SELECT n, 1 + (n % 20),
    CASE (n % 4) WHEN 0 THEN ''paid'' WHEN 1 THEN ''shipped'' WHEN 2 THEN ''delivered'' ELSE ''cancelled'' END,
    date(''2026-01-01'', ''+'' || (n % 31) || '' day'')
  FROM seq;

  WITH RECURSIVE ord(o) AS (SELECT 1 UNION ALL SELECT o+1 FROM ord WHERE o < 50),
  items(k) AS (SELECT 0 UNION ALL SELECT 1)
  INSERT INTO order_items(order_id, product_id, qty)
  SELECT
    o,
    CASE k WHEN 0 THEN 1 + (o % 10) ELSE 1 + ((o + 3) % 10) END,
    CASE k WHEN 0 THEN 1 + (o % 3) ELSE 1 + ((o + 1) % 2) END
  FROM ord CROSS JOIN items;
  ',
  '
  SELECT u.id AS user_id,
         u.name AS name,
         COALESCE(SUM(oi.qty * p.price), 0) AS revenue
  FROM users u
  LEFT JOIN orders o ON o.user_id = u.id
  LEFT JOIN order_items oi ON oi.order_id = o.id
  LEFT JOIN products p ON p.id = oi.product_id
  GROUP BY u.id, u.name
  ORDER BY revenue DESC, user_id ASC;
  ',
  'ordered'
);

-- HARD 2: users who bought from 3+ categories
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Shop: Users with 3+ categories',
  'Find users who purchased items from at least 3 categories.',
  'Hard',
  'Find users who purchased items from at least 3 distinct product categories. Expected columns: user_id, categories_cnt.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, created_at TEXT NOT NULL);
  CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, price REAL NOT NULL);
  CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL, status TEXT NOT NULL, ordered_at TEXT NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id));
  CREATE TABLE order_items (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, qty INTEGER NOT NULL, PRIMARY KEY(order_id, product_id), FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(product_id) REFERENCES products(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO users(id, name, city, created_at)
  SELECT n, ''User '' || n,
    CASE (n % 5) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Berlin'' WHEN 2 THEN ''Paris'' WHEN 3 THEN ''Warsaw'' ELSE ''Rome'' END,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day'')
  FROM seq;

  INSERT INTO products(id, name, category, price) VALUES
    (1,''Laptop'',''Electronics'',999.0),(2,''Mouse'',''Electronics'',25.0),(3,''Keyboard'',''Electronics'',70.0),
    (4,''Coffee beans'',''Grocery'',12.5),(5,''Pasta'',''Grocery'',3.2),(6,''T-shirt'',''Clothes'',19.9),
    (7,''Jeans'',''Clothes'',55.0),(8,''Book'',''Books'',15.0),(9,''Notebook'',''Stationery'',4.5),(10,''Pen'',''Stationery'',1.2);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, user_id, status, ordered_at)
  SELECT n, 1 + (n % 20),
    CASE (n % 4) WHEN 0 THEN ''paid'' WHEN 1 THEN ''shipped'' WHEN 2 THEN ''delivered'' ELSE ''cancelled'' END,
    date(''2026-01-01'', ''+'' || (n % 31) || '' day'')
  FROM seq;

  WITH RECURSIVE ord(o) AS (SELECT 1 UNION ALL SELECT o+1 FROM ord WHERE o < 50),
  items(k) AS (SELECT 0 UNION ALL SELECT 1)
  INSERT INTO order_items(order_id, product_id, qty)
  SELECT
    o,
    CASE k WHEN 0 THEN 1 + (o % 10) ELSE 1 + ((o + 3) % 10) END,
    CASE k WHEN 0 THEN 1 + (o % 3) ELSE 1 + ((o + 1) % 2) END
  FROM ord CROSS JOIN items;
  ',
  '
  SELECT u.id AS user_id,
         COUNT(DISTINCT p.category) AS categories_cnt
  FROM users u
  JOIN orders o ON o.user_id = u.id
  JOIN order_items oi ON oi.order_id = o.id
  JOIN products p ON p.id = oi.product_id
  GROUP BY u.id
  HAVING COUNT(DISTINCT p.category) >= 3
  ORDER BY categories_cnt DESC, user_id ASC;
  ',
  'ordered'
);

-- HARD 3: days with revenue > average daily revenue
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Shop: Days above average revenue',
  'Find dates where revenue is above average daily revenue.',
  'Hard',
  'Compute daily revenue (SUM(qty*price) by ordered_at) and return dates where daily revenue is above average daily revenue. Expected columns: ordered_at, revenue.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, created_at TEXT NOT NULL);
  CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, price REAL NOT NULL);
  CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL, status TEXT NOT NULL, ordered_at TEXT NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id));
  CREATE TABLE order_items (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, qty INTEGER NOT NULL, PRIMARY KEY(order_id, product_id), FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(product_id) REFERENCES products(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO users(id, name, city, created_at)
  SELECT n, ''User '' || n,
    CASE (n % 5) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Berlin'' WHEN 2 THEN ''Paris'' WHEN 3 THEN ''Warsaw'' ELSE ''Rome'' END,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day'')
  FROM seq;

  INSERT INTO products(id, name, category, price) VALUES
    (1,''Laptop'',''Electronics'',999.0),(2,''Mouse'',''Electronics'',25.0),(3,''Keyboard'',''Electronics'',70.0),
    (4,''Coffee beans'',''Grocery'',12.5),(5,''Pasta'',''Grocery'',3.2),(6,''T-shirt'',''Clothes'',19.9),
    (7,''Jeans'',''Clothes'',55.0),(8,''Book'',''Books'',15.0),(9,''Notebook'',''Stationery'',4.5),(10,''Pen'',''Stationery'',1.2);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, user_id, status, ordered_at)
  SELECT n, 1 + (n % 20),
    CASE (n % 4) WHEN 0 THEN ''paid'' WHEN 1 THEN ''shipped'' WHEN 2 THEN ''delivered'' ELSE ''cancelled'' END,
    date(''2026-01-01'', ''+'' || (n % 31) || '' day'')
  FROM seq;

  WITH RECURSIVE ord(o) AS (SELECT 1 UNION ALL SELECT o+1 FROM ord WHERE o < 50),
  items(k) AS (SELECT 0 UNION ALL SELECT 1)
  INSERT INTO order_items(order_id, product_id, qty)
  SELECT
    o,
    CASE k WHEN 0 THEN 1 + (o % 10) ELSE 1 + ((o + 3) % 10) END,
    CASE k WHEN 0 THEN 1 + (o % 3) ELSE 1 + ((o + 1) % 2) END
  FROM ord CROSS JOIN items;
  ',
  '
  WITH daily AS (
    SELECT o.ordered_at AS ordered_at,
           SUM(oi.qty * p.price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN products p ON p.id = oi.product_id
    GROUP BY o.ordered_at
  )
  SELECT ordered_at, revenue
  FROM daily
  WHERE revenue > (SELECT AVG(revenue) FROM daily)
  ORDER BY revenue DESC, ordered_at ASC;
  ',
  'ordered'
);

-- ADVANCED 1: per-user best day by revenue (window function)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Shop: Best revenue day per user',
  'For each user, find the date with max revenue.',
  'Advanced',
  'For each user, find the ordered_at date where their revenue (SUM(qty*price) for that day) is maximum. Return all users, one row each. Expected columns: user_id, best_day, revenue.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, created_at TEXT NOT NULL);
  CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, price REAL NOT NULL);
  CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL, status TEXT NOT NULL, ordered_at TEXT NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id));
  CREATE TABLE order_items (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, qty INTEGER NOT NULL, PRIMARY KEY(order_id, product_id), FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(product_id) REFERENCES products(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO users(id, name, city, created_at)
  SELECT n, ''User '' || n,
    CASE (n % 5) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Berlin'' WHEN 2 THEN ''Paris'' WHEN 3 THEN ''Warsaw'' ELSE ''Rome'' END,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day'')
  FROM seq;

  INSERT INTO products(id, name, category, price) VALUES
    (1,''Laptop'',''Electronics'',999.0),(2,''Mouse'',''Electronics'',25.0),(3,''Keyboard'',''Electronics'',70.0),
    (4,''Coffee beans'',''Grocery'',12.5),(5,''Pasta'',''Grocery'',3.2),(6,''T-shirt'',''Clothes'',19.9),
    (7,''Jeans'',''Clothes'',55.0),(8,''Book'',''Books'',15.0),(9,''Notebook'',''Stationery'',4.5),(10,''Pen'',''Stationery'',1.2);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, user_id, status, ordered_at)
  SELECT n, 1 + (n % 20),
    CASE (n % 4) WHEN 0 THEN ''paid'' WHEN 1 THEN ''shipped'' WHEN 2 THEN ''delivered'' ELSE ''cancelled'' END,
    date(''2026-01-01'', ''+'' || (n % 31) || '' day'')
  FROM seq;

  WITH RECURSIVE ord(o) AS (SELECT 1 UNION ALL SELECT o+1 FROM ord WHERE o < 50),
  items(k) AS (SELECT 0 UNION ALL SELECT 1)
  INSERT INTO order_items(order_id, product_id, qty)
  SELECT
    o,
    CASE k WHEN 0 THEN 1 + (o % 10) ELSE 1 + ((o + 3) % 10) END,
    CASE k WHEN 0 THEN 1 + (o % 3) ELSE 1 + ((o + 1) % 2) END
  FROM ord CROSS JOIN items;
  ',
  '
  WITH user_day AS (
    SELECT o.user_id AS user_id,
           o.ordered_at AS ordered_at,
           SUM(oi.qty * p.price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN products p ON p.id = oi.product_id
    GROUP BY o.user_id, o.ordered_at
  ),
  ranked AS (
    SELECT
      user_id,
      ordered_at,
      revenue,
      ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY revenue DESC, ordered_at ASC) AS rn
    FROM user_day
  )
  SELECT user_id,
         ordered_at AS best_day,
         revenue
  FROM ranked
  WHERE rn = 1
  ORDER BY user_id;
  ',
  'ordered'
);

-- ADVANCED 2: retention - users with orders on 3+ distinct days
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Shop: Users ordering on 3+ days',
  'Find users who placed orders on at least 3 distinct dates.',
  'Advanced',
  'Return users who placed orders on at least 3 distinct ordered_at dates. Expected columns: user_id, days_cnt.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, created_at TEXT NOT NULL);
  CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, price REAL NOT NULL);
  CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL, status TEXT NOT NULL, ordered_at TEXT NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id));
  CREATE TABLE order_items (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, qty INTEGER NOT NULL, PRIMARY KEY(order_id, product_id), FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(product_id) REFERENCES products(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO users(id, name, city, created_at)
  SELECT n, ''User '' || n,
    CASE (n % 5) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Berlin'' WHEN 2 THEN ''Paris'' WHEN 3 THEN ''Warsaw'' ELSE ''Rome'' END,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day'')
  FROM seq;

  INSERT INTO products(id, name, category, price) VALUES
    (1,''Laptop'',''Electronics'',999.0),(2,''Mouse'',''Electronics'',25.0),(3,''Keyboard'',''Electronics'',70.0),
    (4,''Coffee beans'',''Grocery'',12.5),(5,''Pasta'',''Grocery'',3.2),(6,''T-shirt'',''Clothes'',19.9),
    (7,''Jeans'',''Clothes'',55.0),(8,''Book'',''Books'',15.0),(9,''Notebook'',''Stationery'',4.5),(10,''Pen'',''Stationery'',1.2);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, user_id, status, ordered_at)
  SELECT n, 1 + (n % 20),
    CASE (n % 4) WHEN 0 THEN ''paid'' WHEN 1 THEN ''shipped'' WHEN 2 THEN ''delivered'' ELSE ''cancelled'' END,
    date(''2026-01-01'', ''+'' || (n % 31) || '' day'')
  FROM seq;

  WITH RECURSIVE ord(o) AS (SELECT 1 UNION ALL SELECT o+1 FROM ord WHERE o < 50),
  items(k) AS (SELECT 0 UNION ALL SELECT 1)
  INSERT INTO order_items(order_id, product_id, qty)
  SELECT
    o,
    CASE k WHEN 0 THEN 1 + (o % 10) ELSE 1 + ((o + 3) % 10) END,
    CASE k WHEN 0 THEN 1 + (o % 3) ELSE 1 + ((o + 1) % 2) END
  FROM ord CROSS JOIN items;
  ',
  '
  SELECT user_id,
         COUNT(DISTINCT ordered_at) AS days_cnt
  FROM orders
  GROUP BY user_id
  HAVING COUNT(DISTINCT ordered_at) >= 3
  ORDER BY days_cnt DESC, user_id ASC;
  ',
  'ordered'
);

-- ADVANCED 3: median order value (sum items per order) using window-ish logic
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Shop: Median order value',
  'Compute median order value (sum qty*price per order).',
  'Advanced',
  'Compute each order value as SUM(qty*price). Return the median order value. Expected column: median_value.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, created_at TEXT NOT NULL);
  CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, price REAL NOT NULL);
  CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL, status TEXT NOT NULL, ordered_at TEXT NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id));
  CREATE TABLE order_items (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, qty INTEGER NOT NULL, PRIMARY KEY(order_id, product_id), FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(product_id) REFERENCES products(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO users(id, name, city, created_at)
  SELECT n, ''User '' || n,
    CASE (n % 5) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Berlin'' WHEN 2 THEN ''Paris'' WHEN 3 THEN ''Warsaw'' ELSE ''Rome'' END,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day'')
  FROM seq;

  INSERT INTO products(id, name, category, price) VALUES
    (1,''Laptop'',''Electronics'',999.0),(2,''Mouse'',''Electronics'',25.0),(3,''Keyboard'',''Electronics'',70.0),
    (4,''Coffee beans'',''Grocery'',12.5),(5,''Pasta'',''Grocery'',3.2),(6,''T-shirt'',''Clothes'',19.9),
    (7,''Jeans'',''Clothes'',55.0),(8,''Book'',''Books'',15.0),(9,''Notebook'',''Stationery'',4.5),(10,''Pen'',''Stationery'',1.2);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, user_id, status, ordered_at)
  SELECT n, 1 + (n % 20),
    CASE (n % 4) WHEN 0 THEN ''paid'' WHEN 1 THEN ''shipped'' WHEN 2 THEN ''delivered'' ELSE ''cancelled'' END,
    date(''2026-01-01'', ''+'' || (n % 31) || '' day'')
  FROM seq;

  WITH RECURSIVE ord(o) AS (SELECT 1 UNION ALL SELECT o+1 FROM ord WHERE o < 50),
  items(k) AS (SELECT 0 UNION ALL SELECT 1)
  INSERT INTO order_items(order_id, product_id, qty)
  SELECT
    o,
    CASE k WHEN 0 THEN 1 + (o % 10) ELSE 1 + ((o + 3) % 10) END,
    CASE k WHEN 0 THEN 1 + (o % 3) ELSE 1 + ((o + 1) % 2) END
  FROM ord CROSS JOIN items;
  ',
  '
  WITH order_values AS (
    SELECT o.id AS order_id,
           SUM(oi.qty * p.price) AS value
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN products p ON p.id = oi.product_id
    GROUP BY o.id
  )
  SELECT AVG(value) AS median_value
  FROM (
    SELECT value
    FROM order_values
    ORDER BY value
    LIMIT 2 - (SELECT COUNT(*) FROM order_values) % 2
    OFFSET (SELECT (COUNT(*) - 1) / 2 FROM order_values)
  );
  ',
  'unordered'
);

-- =========================
-- DATASET: CLINIC (patients / doctors / appointments)
-- =========================

-- EASY 1: пациенты из Amsterdam
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Clinic: Пациенты из Amsterdam',
  'Вывести пациентов, живущих в Amsterdam.',
  'Easy',
  'Выведите всех пациентов, которые живут в городе Amsterdam. Ожидаемые колонки: id, full_name, city.',
  '
  PRAGMA foreign_keys = ON;

  CREATE TABLE patients (
    id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    birth_year INTEGER NOT NULL,
    city TEXT NOT NULL
  );

  CREATE TABLE doctors (
    id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    specialty TEXT NOT NULL
  );

  CREATE TABLE appointments (
    id INTEGER PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    visit_date TEXT NOT NULL,
    duration_min INTEGER NOT NULL,
    diagnosis TEXT,
    FOREIGN KEY(patient_id) REFERENCES patients(id),
    FOREIGN KEY(doctor_id) REFERENCES doctors(id)
  );
  ',
  '
  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 25
  )
  INSERT OR IGNORE INTO patients(id, full_name, birth_year, city)
  SELECT
    n,
    ''Patient '' || n,
    1955 + (n % 45),
    CASE (n % 4)
      WHEN 0 THEN ''Amsterdam''
      WHEN 1 THEN ''Utrecht''
      WHEN 2 THEN ''Rotterdam''
      ELSE ''Eindhoven''
    END
  FROM seq;

  INSERT OR IGNORE INTO doctors(id, full_name, specialty) VALUES
    (1,''Dr. Adams'',''Therapist''),
    (2,''Dr. Brown'',''Dermatologist''),
    (3,''Dr. Clark'',''Cardiologist''),
    (4,''Dr. Davis'',''Neurologist''),
    (5,''Dr. Evans'',''Pediatrician'');

  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 50
  )
  INSERT OR IGNORE INTO appointments(id, patient_id, doctor_id, visit_date, duration_min, diagnosis)
  SELECT
    n,
    1 + (n % 25),
    1 + (n % 5),
    date(''2026-01-03'', ''+'' || (n % 30) || '' day''),
    15 + (n % 4) * 10,
    CASE (n % 6)
      WHEN 0 THEN ''checkup''
      WHEN 1 THEN ''allergy''
      WHEN 2 THEN ''flu''
      WHEN 3 THEN ''back_pain''
      WHEN 4 THEN ''skin_rash''
      ELSE NULL
    END
  FROM seq;
  ',
  '
  SELECT id, full_name, city
  FROM patients
  WHERE city = ''Amsterdam''
  ORDER BY id;
  ',
  'ordered'
);

-- EASY 2: посчитать количество визитов
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Clinic: Количество визитов',
  'Посчитать общее число визитов (appointments).',
  'Easy',
  'Подсчитайте количество строк в таблице appointments. Ожидаемая колонка: visits_cnt.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE patients (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, birth_year INTEGER NOT NULL, city TEXT NOT NULL);
  CREATE TABLE doctors (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, specialty TEXT NOT NULL);
  CREATE TABLE appointments (id INTEGER PRIMARY KEY, patient_id INTEGER NOT NULL, doctor_id INTEGER NOT NULL, visit_date TEXT NOT NULL, duration_min INTEGER NOT NULL, diagnosis TEXT,
    FOREIGN KEY(patient_id) REFERENCES patients(id), FOREIGN KEY(doctor_id) REFERENCES doctors(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 25)
  INSERT OR IGNORE INTO patients(id, full_name, birth_year, city)
  SELECT n, ''Patient '' || n, 1955 + (n % 45),
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  INSERT OR IGNORE INTO doctors(id, full_name, specialty) VALUES
    (1,''Dr. Adams'',''Therapist''),(2,''Dr. Brown'',''Dermatologist''),(3,''Dr. Clark'',''Cardiologist''),
    (4,''Dr. Davis'',''Neurologist''),(5,''Dr. Evans'',''Pediatrician'');

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT OR IGNORE INTO appointments(id, patient_id, doctor_id, visit_date, duration_min, diagnosis)
  SELECT n, 1 + (n % 25), 1 + (n % 5),
    date(''2026-01-03'', ''+'' || (n % 30) || '' day''),
    15 + (n % 4) * 10,
    CASE (n % 6) WHEN 0 THEN ''checkup'' WHEN 1 THEN ''allergy'' WHEN 2 THEN ''flu'' WHEN 3 THEN ''back_pain'' WHEN 4 THEN ''skin_rash'' ELSE NULL END
  FROM seq;
  ',
  '
  SELECT COUNT(*) AS visits_cnt
  FROM appointments;
  ',
  'unordered'
);

-- EASY 3: список врачей-кардиологов
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Clinic: Врачи-кардиологи',
  'Вывести врачей со специальностью Cardiologist.',
  'Easy',
  'Выведите всех врачей, чья специальность равна Cardiologist. Ожидаемые колонки: id, full_name, specialty.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE patients (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, birth_year INTEGER NOT NULL, city TEXT NOT NULL);
  CREATE TABLE doctors (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, specialty TEXT NOT NULL);
  CREATE TABLE appointments (id INTEGER PRIMARY KEY, patient_id INTEGER NOT NULL, doctor_id INTEGER NOT NULL, visit_date TEXT NOT NULL, duration_min INTEGER NOT NULL, diagnosis TEXT,
    FOREIGN KEY(patient_id) REFERENCES patients(id), FOREIGN KEY(doctor_id) REFERENCES doctors(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 25)
  INSERT OR IGNORE INTO patients(id, full_name, birth_year, city)
  SELECT n, ''Patient '' || n, 1955 + (n % 45),
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  INSERT OR IGNORE INTO doctors(id, full_name, specialty) VALUES
    (1,''Dr. Adams'',''Therapist''),(2,''Dr. Brown'',''Dermatologist''),(3,''Dr. Clark'',''Cardiologist''),
    (4,''Dr. Davis'',''Neurologist''),(5,''Dr. Evans'',''Pediatrician'');

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT OR IGNORE INTO appointments(id, patient_id, doctor_id, visit_date, duration_min, diagnosis)
  SELECT n, 1 + (n % 25), 1 + (n % 5),
    date(''2026-01-03'', ''+'' || (n % 30) || '' day''),
    15 + (n % 4) * 10,
    CASE (n % 6) WHEN 0 THEN ''checkup'' WHEN 1 THEN ''allergy'' WHEN 2 THEN ''flu'' WHEN 3 THEN ''back_pain'' WHEN 4 THEN ''skin_rash'' ELSE NULL END
  FROM seq;
  ',
  '
  SELECT id, full_name, specialty
  FROM doctors
  WHERE specialty = ''Cardiologist''
  ORDER BY id;
  ',
  'ordered'
);

-- MEDIUM 1: количество визитов по каждому врачу
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Clinic: Визиты по врачам',
  'Посчитать количество визитов у каждого врача.',
  'Medium',
  'Для каждого врача посчитайте количество визитов. В результате должны быть все врачи (даже если у врача 0 визитов). Ожидаемые колонки: doctor_id, doctor_name, visits_cnt.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE patients (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, birth_year INTEGER NOT NULL, city TEXT NOT NULL);
  CREATE TABLE doctors (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, specialty TEXT NOT NULL);
  CREATE TABLE appointments (id INTEGER PRIMARY KEY, patient_id INTEGER NOT NULL, doctor_id INTEGER NOT NULL, visit_date TEXT NOT NULL, duration_min INTEGER NOT NULL, diagnosis TEXT,
    FOREIGN KEY(patient_id) REFERENCES patients(id), FOREIGN KEY(doctor_id) REFERENCES doctors(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 25)
  INSERT OR IGNORE INTO patients(id, full_name, birth_year, city)
  SELECT n, ''Patient '' || n, 1955 + (n % 45),
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  INSERT OR IGNORE INTO doctors(id, full_name, specialty) VALUES
    (1,''Dr. Adams'',''Therapist''),(2,''Dr. Brown'',''Dermatologist''),(3,''Dr. Clark'',''Cardiologist''),
    (4,''Dr. Davis'',''Neurologist''),(5,''Dr. Evans'',''Pediatrician'');

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT OR IGNORE INTO appointments(id, patient_id, doctor_id, visit_date, duration_min, diagnosis)
  SELECT n, 1 + (n % 25), 1 + (n % 5),
    date(''2026-01-03'', ''+'' || (n % 30) || '' day''),
    15 + (n % 4) * 10,
    CASE (n % 6) WHEN 0 THEN ''checkup'' WHEN 1 THEN ''allergy'' WHEN 2 THEN ''flu'' WHEN 3 THEN ''back_pain'' WHEN 4 THEN ''skin_rash'' ELSE NULL END
  FROM seq;
  ',
  '
  SELECT d.id AS doctor_id,
         d.full_name AS doctor_name,
         COUNT(a.id) AS visits_cnt
  FROM doctors d
  LEFT JOIN appointments a ON a.doctor_id = d.id
  GROUP BY d.id, d.full_name
  ORDER BY visits_cnt DESC, doctor_id ASC;
  ',
  'ordered'
);

-- MEDIUM 2: средняя длительность визита по диагнозу (без NULL)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Clinic: Средняя длительность по диагнозу',
  'Средняя длительность визита по каждому диагнозу.',
  'Medium',
  'Посчитайте среднюю длительность (AVG(duration_min)) по каждому диагнозу. Не включайте записи, где diagnosis = NULL. Ожидаемые колонки: diagnosis, avg_duration.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE patients (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, birth_year INTEGER NOT NULL, city TEXT NOT NULL);
  CREATE TABLE doctors (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, specialty TEXT NOT NULL);
  CREATE TABLE appointments (id INTEGER PRIMARY KEY, patient_id INTEGER NOT NULL, doctor_id INTEGER NOT NULL, visit_date TEXT NOT NULL, duration_min INTEGER NOT NULL, diagnosis TEXT,
    FOREIGN KEY(patient_id) REFERENCES patients(id), FOREIGN KEY(doctor_id) REFERENCES doctors(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 25)
  INSERT OR IGNORE INTO patients(id, full_name, birth_year, city)
  SELECT n, ''Patient '' || n, 1955 + (n % 45),
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  INSERT OR IGNORE INTO doctors(id, full_name, specialty) VALUES
    (1,''Dr. Adams'',''Therapist''),(2,''Dr. Brown'',''Dermatologist''),(3,''Dr. Clark'',''Cardiologist''),
    (4,''Dr. Davis'',''Neurologist''),(5,''Dr. Evans'',''Pediatrician'');

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT OR IGNORE INTO appointments(id, patient_id, doctor_id, visit_date, duration_min, diagnosis)
  SELECT n, 1 + (n % 25), 1 + (n % 5),
    date(''2026-01-03'', ''+'' || (n % 30) || '' day''),
    15 + (n % 4) * 10,
    CASE (n % 6) WHEN 0 THEN ''checkup'' WHEN 1 THEN ''allergy'' WHEN 2 THEN ''flu'' WHEN 3 THEN ''back_pain'' WHEN 4 THEN ''skin_rash'' ELSE NULL END
  FROM seq;
  ',
  '
  SELECT diagnosis,
         AVG(duration_min) AS avg_duration
  FROM appointments
  WHERE diagnosis IS NOT NULL
  GROUP BY diagnosis
  ORDER BY avg_duration DESC, diagnosis ASC;
  ',
  'ordered'
);

-- MEDIUM 3: пациенты без визитов
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Clinic: Пациенты без визитов',
  'Найти пациентов, у которых нет визитов.',
  'Medium',
  'Выведите пациентов, которые ни разу не приходили на приём. Ожидаемые колонки: patient_id, full_name.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE patients (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, birth_year INTEGER NOT NULL, city TEXT NOT NULL);
  CREATE TABLE doctors (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, specialty TEXT NOT NULL);
  CREATE TABLE appointments (id INTEGER PRIMARY KEY, patient_id INTEGER NOT NULL, doctor_id INTEGER NOT NULL, visit_date TEXT NOT NULL, duration_min INTEGER NOT NULL, diagnosis TEXT,
    FOREIGN KEY(patient_id) REFERENCES patients(id), FOREIGN KEY(doctor_id) REFERENCES doctors(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 25)
  INSERT OR IGNORE INTO patients(id, full_name, birth_year, city)
  SELECT n, ''Patient '' || n, 1955 + (n % 45),
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  INSERT OR IGNORE INTO doctors(id, full_name, specialty) VALUES
    (1,''Dr. Adams'',''Therapist''),(2,''Dr. Brown'',''Dermatologist''),(3,''Dr. Clark'',''Cardiologist''),
    (4,''Dr. Davis'',''Neurologist''),(5,''Dr. Evans'',''Pediatrician'');

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT OR IGNORE INTO appointments(id, patient_id, doctor_id, visit_date, duration_min, diagnosis)
  SELECT n, 1 + (n % 25), 1 + (n % 5),
    date(''2026-01-03'', ''+'' || (n % 30) || '' day''),
    15 + (n % 4) * 10,
    CASE (n % 6) WHEN 0 THEN ''checkup'' WHEN 1 THEN ''allergy'' WHEN 2 THEN ''flu'' WHEN 3 THEN ''back_pain'' WHEN 4 THEN ''skin_rash'' ELSE NULL END
  FROM seq;
  ',
  '
  SELECT p.id AS patient_id,
         p.full_name AS full_name
  FROM patients p
  LEFT JOIN appointments a ON a.patient_id = p.id
  WHERE a.id IS NULL
  ORDER BY patient_id;
  ',
  'ordered'
);

-- HARD 1: топ-3 диагноза по частоте (NULL не учитываем)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Clinic: Топ диагнозов',
  'Найти 3 самых частых диагноза.',
  'Hard',
  'Найдите 3 диагноза, которые встречаются чаще всего. Записи с diagnosis = NULL не учитывать. Ожидаемые колонки: diagnosis, cnt.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE patients (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, birth_year INTEGER NOT NULL, city TEXT NOT NULL);
  CREATE TABLE doctors (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, specialty TEXT NOT NULL);
  CREATE TABLE appointments (id INTEGER PRIMARY KEY, patient_id INTEGER NOT NULL, doctor_id INTEGER NOT NULL, visit_date TEXT NOT NULL, duration_min INTEGER NOT NULL, diagnosis TEXT,
    FOREIGN KEY(patient_id) REFERENCES patients(id), FOREIGN KEY(doctor_id) REFERENCES doctors(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 25)
  INSERT OR IGNORE INTO patients(id, full_name, birth_year, city)
  SELECT n, ''Patient '' || n, 1955 + (n % 45),
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  INSERT OR IGNORE INTO doctors(id, full_name, specialty) VALUES
    (1,''Dr. Adams'',''Therapist''),(2,''Dr. Brown'',''Dermatologist''),(3,''Dr. Clark'',''Cardiologist''),
    (4,''Dr. Davis'',''Neurologist''),(5,''Dr. Evans'',''Pediatrician'');

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT OR IGNORE INTO appointments(id, patient_id, doctor_id, visit_date, duration_min, diagnosis)
  SELECT n, 1 + (n % 25), 1 + (n % 5),
    date(''2026-01-03'', ''+'' || (n % 30) || '' day''),
    15 + (n % 4) * 10,
    CASE (n % 6) WHEN 0 THEN ''checkup'' WHEN 1 THEN ''allergy'' WHEN 2 THEN ''flu'' WHEN 3 THEN ''back_pain'' WHEN 4 THEN ''skin_rash'' ELSE NULL END
  FROM seq;
  ',
  '
  SELECT diagnosis,
         COUNT(*) AS cnt
  FROM appointments
  WHERE diagnosis IS NOT NULL
  GROUP BY diagnosis
  ORDER BY cnt DESC, diagnosis ASC
  LIMIT 3;
  ',
  'ordered'
);

-- HARD 2: пациенты с длительностью визитов выше средней (по всем визитам)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Clinic: Визиты выше средней длительности',
  'Найти визиты, которые длиннее среднего по всем визитам.',
  'Hard',
  'Выведите визиты, у которых duration_min больше среднего значения duration_min по всем визитам. Ожидаемые колонки: id, patient_id, duration_min.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE patients (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, birth_year INTEGER NOT NULL, city TEXT NOT NULL);
  CREATE TABLE doctors (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, specialty TEXT NOT NULL);
  CREATE TABLE appointments (id INTEGER PRIMARY KEY, patient_id INTEGER NOT NULL, doctor_id INTEGER NOT NULL, visit_date TEXT NOT NULL, duration_min INTEGER NOT NULL, diagnosis TEXT,
    FOREIGN KEY(patient_id) REFERENCES patients(id), FOREIGN KEY(doctor_id) REFERENCES doctors(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 25)
  INSERT OR IGNORE INTO patients(id, full_name, birth_year, city)
  SELECT n, ''Patient '' || n, 1955 + (n % 45),
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  INSERT OR IGNORE INTO doctors(id, full_name, specialty) VALUES
    (1,''Dr. Adams'',''Therapist''),(2,''Dr. Brown'',''Dermatologist''),(3,''Dr. Clark'',''Cardiologist''),
    (4,''Dr. Davis'',''Neurologist''),(5,''Dr. Evans'',''Pediatrician'');

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT OR IGNORE INTO appointments(id, patient_id, doctor_id, visit_date, duration_min, diagnosis)
  SELECT n, 1 + (n % 25), 1 + (n % 5),
    date(''2026-01-03'', ''+'' || (n % 30) || '' day''),
    15 + (n % 4) * 10,
    CASE (n % 6) WHEN 0 THEN ''checkup'' WHEN 1 THEN ''allergy'' WHEN 2 THEN ''flu'' WHEN 3 THEN ''back_pain'' WHEN 4 THEN ''skin_rash'' ELSE NULL END
  FROM seq;
  ',
  '
  SELECT id, patient_id, duration_min
  FROM appointments
  WHERE duration_min > (SELECT AVG(duration_min) FROM appointments)
  ORDER BY duration_min DESC, id ASC;
  ',
  'ordered'
);

-- HARD 3: у каких врачей больше 10 визитов
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Clinic: Врачи с большим числом визитов',
  'Найти врачей, у которых больше 10 визитов.',
  'Hard',
  'Выведите врачей, у которых количество визитов строго больше 10. Ожидаемые колонки: doctor_id, visits_cnt.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE patients (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, birth_year INTEGER NOT NULL, city TEXT NOT NULL);
  CREATE TABLE doctors (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, specialty TEXT NOT NULL);
  CREATE TABLE appointments (id INTEGER PRIMARY KEY, patient_id INTEGER NOT NULL, doctor_id INTEGER NOT NULL, visit_date TEXT NOT NULL, duration_min INTEGER NOT NULL, diagnosis TEXT,
    FOREIGN KEY(patient_id) REFERENCES patients(id), FOREIGN KEY(doctor_id) REFERENCES doctors(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 25)
  INSERT OR IGNORE INTO patients(id, full_name, birth_year, city)
  SELECT n, ''Patient '' || n, 1955 + (n % 45),
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  INSERT OR IGNORE INTO doctors(id, full_name, specialty) VALUES
    (1,''Dr. Adams'',''Therapist''),(2,''Dr. Brown'',''Dermatologist''),(3,''Dr. Clark'',''Cardiologist''),
    (4,''Dr. Davis'',''Neurologist''),(5,''Dr. Evans'',''Pediatrician'');

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT OR IGNORE INTO appointments(id, patient_id, doctor_id, visit_date, duration_min, diagnosis)
  SELECT n, 1 + (n % 25), 1 + (n % 5),
    date(''2026-01-03'', ''+'' || (n % 30) || '' day''),
    15 + (n % 4) * 10,
    CASE (n % 6) WHEN 0 THEN ''checkup'' WHEN 1 THEN ''allergy'' WHEN 2 THEN ''flu'' WHEN 3 THEN ''back_pain'' WHEN 4 THEN ''skin_rash'' ELSE NULL END
  FROM seq;
  ',
  '
  SELECT doctor_id,
         COUNT(*) AS visits_cnt
  FROM appointments
  GROUP BY doctor_id
  HAVING COUNT(*) > 10
  ORDER BY visits_cnt DESC, doctor_id ASC;
  ',
  'ordered'
);

-- ADVANCED 1: самый популярный диагноз по каждому врачу (оконная функция)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Clinic: Частый диагноз у каждого врача',
  'Для каждого врача найти самый частый диагноз.',
  'Advanced',
  'Для каждого врача найдите диагноз, который встречается у него чаще всего. Игнорируйте diagnosis = NULL. Если несколько диагнозов с одинаковой частотой — выберите лексикографически меньший. Ожидаемые колонки: doctor_id, diagnosis, cnt.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE patients (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, birth_year INTEGER NOT NULL, city TEXT NOT NULL);
  CREATE TABLE doctors (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, specialty TEXT NOT NULL);
  CREATE TABLE appointments (id INTEGER PRIMARY KEY, patient_id INTEGER NOT NULL, doctor_id INTEGER NOT NULL, visit_date TEXT NOT NULL, duration_min INTEGER NOT NULL, diagnosis TEXT,
    FOREIGN KEY(patient_id) REFERENCES patients(id), FOREIGN KEY(doctor_id) REFERENCES doctors(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 25)
  INSERT OR IGNORE INTO patients(id, full_name, birth_year, city)
  SELECT n, ''Patient '' || n, 1955 + (n % 45),
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  INSERT OR IGNORE INTO doctors(id, full_name, specialty) VALUES
    (1,''Dr. Adams'',''Therapist''),(2,''Dr. Brown'',''Dermatologist''),(3,''Dr. Clark'',''Cardiologist''),
    (4,''Dr. Davis'',''Neurologist''),(5,''Dr. Evans'',''Pediatrician'');

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT OR IGNORE INTO appointments(id, patient_id, doctor_id, visit_date, duration_min, diagnosis)
  SELECT n, 1 + (n % 25), 1 + (n % 5),
    date(''2026-01-03'', ''+'' || (n % 30) || '' day''),
    15 + (n % 4) * 10,
    CASE (n % 6) WHEN 0 THEN ''checkup'' WHEN 1 THEN ''allergy'' WHEN 2 THEN ''flu'' WHEN 3 THEN ''back_pain'' WHEN 4 THEN ''skin_rash'' ELSE NULL END
  FROM seq;
  ',
  '
  WITH counts AS (
    SELECT doctor_id,
           diagnosis,
           COUNT(*) AS cnt
    FROM appointments
    WHERE diagnosis IS NOT NULL
    GROUP BY doctor_id, diagnosis
  ),
  ranked AS (
    SELECT doctor_id,
           diagnosis,
           cnt,
           ROW_NUMBER() OVER (PARTITION BY doctor_id ORDER BY cnt DESC, diagnosis ASC) AS rn
    FROM counts
  )
  SELECT doctor_id, diagnosis, cnt
  FROM ranked
  WHERE rn = 1
  ORDER BY doctor_id;
  ',
  'ordered'
);

-- ADVANCED 2: дни с максимальным числом визитов
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Clinic: Пиковые дни по визитам',
  'Найти дни, когда было максимальное число визитов.',
  'Advanced',
  'Найдите даты visit_date, в которые было максимальное количество визитов. Если таких дат несколько — верните все. Ожидаемые колонки: visit_date, visits_cnt.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE patients (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, birth_year INTEGER NOT NULL, city TEXT NOT NULL);
  CREATE TABLE doctors (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, specialty TEXT NOT NULL);
  CREATE TABLE appointments (id INTEGER PRIMARY KEY, patient_id INTEGER NOT NULL, doctor_id INTEGER NOT NULL, visit_date TEXT NOT NULL, duration_min INTEGER NOT NULL, diagnosis TEXT,
    FOREIGN KEY(patient_id) REFERENCES patients(id), FOREIGN KEY(doctor_id) REFERENCES doctors(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 25)
  INSERT OR IGNORE INTO patients(id, full_name, birth_year, city)
  SELECT n, ''Patient '' || n, 1955 + (n % 45),
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  INSERT OR IGNORE INTO doctors(id, full_name, specialty) VALUES
    (1,''Dr. Adams'',''Therapist''),(2,''Dr. Brown'',''Dermatologist''),(3,''Dr. Clark'',''Cardiologist''),
    (4,''Dr. Davis'',''Neurologist''),(5,''Dr. Evans'',''Pediatrician'');

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT OR IGNORE INTO appointments(id, patient_id, doctor_id, visit_date, duration_min, diagnosis)
  SELECT n, 1 + (n % 25), 1 + (n % 5),
    date(''2026-01-03'', ''+'' || (n % 30) || '' day''),
    15 + (n % 4) * 10,
    CASE (n % 6) WHEN 0 THEN ''checkup'' WHEN 1 THEN ''allergy'' WHEN 2 THEN ''flu'' WHEN 3 THEN ''back_pain'' WHEN 4 THEN ''skin_rash'' ELSE NULL END
  FROM seq;
  ',
  '
  WITH daily AS (
    SELECT visit_date,
           COUNT(*) AS visits_cnt
    FROM appointments
    GROUP BY visit_date
  )
  SELECT visit_date, visits_cnt
  FROM daily
  WHERE visits_cnt = (SELECT MAX(visits_cnt) FROM daily)
  ORDER BY visit_date;
  ',
  'ordered'
);

-- ADVANCED 3: медиана длительности визитов (по всем визитам)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Clinic: Медиана длительности визита',
  'Посчитать медиану duration_min по всем визитам.',
  'Advanced',
  'Посчитайте медиану длительности визита (duration_min) по всем записям appointments. Ожидаемая колонка: median_duration.',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE patients (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, birth_year INTEGER NOT NULL, city TEXT NOT NULL);
  CREATE TABLE doctors (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, specialty TEXT NOT NULL);
  CREATE TABLE appointments (id INTEGER PRIMARY KEY, patient_id INTEGER NOT NULL, doctor_id INTEGER NOT NULL, visit_date TEXT NOT NULL, duration_min INTEGER NOT NULL, diagnosis TEXT,
    FOREIGN KEY(patient_id) REFERENCES patients(id), FOREIGN KEY(doctor_id) REFERENCES doctors(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 25)
  INSERT OR IGNORE INTO patients(id, full_name, birth_year, city)
  SELECT n, ''Patient '' || n, 1955 + (n % 45),
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  INSERT OR IGNORE INTO doctors(id, full_name, specialty) VALUES
    (1,''Dr. Adams'',''Therapist''),(2,''Dr. Brown'',''Dermatologist''),(3,''Dr. Clark'',''Cardiologist''),
    (4,''Dr. Davis'',''Neurologist''),(5,''Dr. Evans'',''Pediatrician'');

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT OR IGNORE INTO appointments(id, patient_id, doctor_id, visit_date, duration_min, diagnosis)
  SELECT n, 1 + (n % 25), 1 + (n % 5),
    date(''2026-01-03'', ''+'' || (n % 30) || '' day''),
    15 + (n % 4) * 10,
    CASE (n % 6) WHEN 0 THEN ''checkup'' WHEN 1 THEN ''allergy'' WHEN 2 THEN ''flu'' WHEN 3 THEN ''back_pain'' WHEN 4 THEN ''skin_rash'' ELSE NULL END
  FROM seq;
  ',
  '
  SELECT AVG(duration_min) AS median_duration
  FROM (
    SELECT duration_min
    FROM appointments
    ORDER BY duration_min
    LIMIT 2 - (SELECT COUNT(*) FROM appointments) % 2
    OFFSET (SELECT (COUNT(*) - 1) / 2 FROM appointments)
  );
  ',
  'unordered'
);



-- =========================
-- DATASET: CINEMA (viewers / movies / views / ratings)
-- =========================

-- EASY 1: все фильмы жанра Sci-Fi
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Cinema: Фильмы жанра Sci-Fi',
  'Вывести фильмы жанра Sci-Fi.',
  'Easy',
  'Выведите список фильмов, у которых genre = Sci-Fi
   Ожидаемые колонки: id, title, release_year',
  '
  PRAGMA foreign_keys = ON;

  CREATE TABLE viewers (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    country TEXT NOT NULL,
    joined_at TEXT NOT NULL
  );

  CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    genre TEXT NOT NULL,
    release_year INTEGER NOT NULL
  );

  CREATE TABLE views (
    id INTEGER PRIMARY KEY,
    viewer_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    watched_at TEXT NOT NULL,
    minutes_watched INTEGER NOT NULL,
    FOREIGN KEY(viewer_id) REFERENCES viewers(id),
    FOREIGN KEY(movie_id) REFERENCES movies(id)
  );

  CREATE TABLE ratings (
    viewer_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    rating INTEGER NOT NULL,
    PRIMARY KEY(viewer_id, movie_id),
    FOREIGN KEY(viewer_id) REFERENCES viewers(id),
    FOREIGN KEY(movie_id) REFERENCES movies(id)
  );
  ',
  '
  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 20
  )
  INSERT INTO viewers(id, username, country, joined_at)
  SELECT
    n,
    ''user_'' || n,
    CASE (n % 5)
      WHEN 0 THEN ''NL''
      WHEN 1 THEN ''DE''
      WHEN 2 THEN ''FR''
      WHEN 3 THEN ''PL''
      ELSE ''IT''
    END,
    date(''2025-12-01'', ''+'' || (n % 40) || '' day'')
  FROM seq;

  INSERT INTO movies(id, title, genre, release_year) VALUES
    (1,''Skyline'',''Sci-Fi'',2020),
    (2,''City Lights'',''Drama'',2019),
    (3,''Fast Lane'',''Action'',2021),
    (4,''Deep Sea'',''Documentary'',2018),
    (5,''Laugh Out'',''Comedy'',2022),
    (6,''Old Tales'',''Drama'',2017),
    (7,''Mystery House'',''Thriller'',2023),
    (8,''Space Walk'',''Sci-Fi'',2024),
    (9,''Green Planet'',''Documentary'',2021),
    (10,''Love Story'',''Romance'',2020);

  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 50
  )
  INSERT INTO views(id, viewer_id, movie_id, watched_at, minutes_watched)
  SELECT
    n,
    1 + (n % 20),
    1 + (n % 10),
    datetime(''2026-01-01 10:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 15) || '' days''),
    20 + (n % 9) * 10
  FROM seq;

  -- Ratings: гарантируем уникальность (viewer_id, movie_id)
  -- Ровно 2 оценки на каждого зрителя (1..20), movie_id отличаются (смещение +3)
  WITH RECURSIVE v(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM v WHERE n < 20
  )
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT
    n AS viewer_id,
    1 + (n % 10) AS movie_id,
    1 + (n % 5) AS rating
  FROM v;

  WITH RECURSIVE v(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM v WHERE n < 20
  )
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT
    n AS viewer_id,
    1 + ((n + 3) % 10) AS movie_id,
    1 + ((n + 2) % 5) AS rating
  FROM v;
  ',
  '
  SELECT id, title, release_year
  FROM movies
  WHERE genre = ''Sci-Fi''
  ORDER BY release_year DESC, id ASC;
  ',
  'ordered'
);

-- EASY 2: количество фильмов по жанрам
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Cinema: Количество фильмов по жанрам',
  'Посчитать число фильмов в каждом жанре.',
  'Easy',
  'Сгруппируйте фильмы по genre и посчитайте количество
   Ожидаемые колонки: genre, movies_cnt',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE viewers (id INTEGER PRIMARY KEY, username TEXT NOT NULL, country TEXT NOT NULL, joined_at TEXT NOT NULL);
  CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT NOT NULL, genre TEXT NOT NULL, release_year INTEGER NOT NULL);
  CREATE TABLE views (id INTEGER PRIMARY KEY, viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, watched_at TEXT NOT NULL, minutes_watched INTEGER NOT NULL,
    FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  CREATE TABLE ratings (viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, rating INTEGER NOT NULL,
    PRIMARY KEY(viewer_id, movie_id), FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO viewers(id, username, country, joined_at)
  SELECT n, ''user_'' || n,
    CASE (n % 5) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' WHEN 3 THEN ''PL'' ELSE ''IT'' END,
    date(''2025-12-01'', ''+'' || (n % 40) || '' day'')
  FROM seq;

  INSERT INTO movies(id, title, genre, release_year) VALUES
    (1,''Skyline'',''Sci-Fi'',2020),(2,''City Lights'',''Drama'',2019),(3,''Fast Lane'',''Action'',2021),
    (4,''Deep Sea'',''Documentary'',2018),(5,''Laugh Out'',''Comedy'',2022),(6,''Old Tales'',''Drama'',2017),
    (7,''Mystery House'',''Thriller'',2023),(8,''Space Walk'',''Sci-Fi'',2024),(9,''Green Planet'',''Documentary'',2021),
    (10,''Love Story'',''Romance'',2020);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO views(id, viewer_id, movie_id, watched_at, minutes_watched)
  SELECT n, 1 + (n % 20), 1 + (n % 10),
    datetime(''2026-01-01 10:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 15) || '' days''),
    20 + (n % 9) * 10
  FROM seq;

  -- Ratings without duplicates
  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + (n % 10), 1 + (n % 5) FROM v;

  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + ((n + 3) % 10), 1 + ((n + 2) % 5) FROM v;
  ',
  '
  SELECT genre, COUNT(*) AS movies_cnt
  FROM movies
  GROUP BY genre
  ORDER BY movies_cnt DESC, genre ASC;
  ',
  'ordered'
);

-- EASY 3: просмотры с длительностью >= 60 минут
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Cinema: Длинные просмотры',
  'Найти просмотры длительностью 60 минут и больше.',
  'Easy',
  'Выведите просмотры, где minutes_watched >= 60
   Ожидаемые колонки: id, viewer_id, movie_id, minutes_watched',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE viewers (id INTEGER PRIMARY KEY, username TEXT NOT NULL, country TEXT NOT NULL, joined_at TEXT NOT NULL);
  CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT NOT NULL, genre TEXT NOT NULL, release_year INTEGER NOT NULL);
  CREATE TABLE views (id INTEGER PRIMARY KEY, viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, watched_at TEXT NOT NULL, minutes_watched INTEGER NOT NULL,
    FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  CREATE TABLE ratings (viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, rating INTEGER NOT NULL,
    PRIMARY KEY(viewer_id, movie_id), FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO viewers(id, username, country, joined_at)
  SELECT n, ''user_'' || n,
    CASE (n % 5) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' WHEN 3 THEN ''PL'' ELSE ''IT'' END,
    date(''2025-12-01'', ''+'' || (n % 40) || '' day'')
  FROM seq;

  INSERT INTO movies(id, title, genre, release_year) VALUES
    (1,''Skyline'',''Sci-Fi'',2020),(2,''City Lights'',''Drama'',2019),(3,''Fast Lane'',''Action'',2021),
    (4,''Deep Sea'',''Documentary'',2018),(5,''Laugh Out'',''Comedy'',2022),(6,''Old Tales'',''Drama'',2017),
    (7,''Mystery House'',''Thriller'',2023),(8,''Space Walk'',''Sci-Fi'',2024),(9,''Green Planet'',''Documentary'',2021),
    (10,''Love Story'',''Romance'',2020);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO views(id, viewer_id, movie_id, watched_at, minutes_watched)
  SELECT n, 1 + (n % 20), 1 + (n % 10),
    datetime(''2026-01-01 10:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 15) || '' days''),
    20 + (n % 9) * 10
  FROM seq;

  -- Ratings without duplicates
  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + (n % 10), 1 + (n % 5) FROM v;

  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + ((n + 3) % 10), 1 + ((n + 2) % 5) FROM v;
  ',
  '
  SELECT id, viewer_id, movie_id, minutes_watched
  FROM views
  WHERE minutes_watched >= 60
  ORDER BY minutes_watched DESC, id ASC;
  ',
  'ordered'
);

-- MEDIUM 1: топ-5 самых просматриваемых фильмов по количеству просмотров
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Cinema: Топ фильмов по просмотрам',
  'Найти 5 фильмов с максимальным числом просмотров.',
  'Medium',
  'Посчитайте количество просмотров для каждого фильма и выведите топ-5
   Ожидаемые колонки: movie_id, title, views_cnt',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE viewers (id INTEGER PRIMARY KEY, username TEXT NOT NULL, country TEXT NOT NULL, joined_at TEXT NOT NULL);
  CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT NOT NULL, genre TEXT NOT NULL, release_year INTEGER NOT NULL);
  CREATE TABLE views (id INTEGER PRIMARY KEY, viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, watched_at TEXT NOT NULL, minutes_watched INTEGER NOT NULL,
    FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  CREATE TABLE ratings (viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, rating INTEGER NOT NULL,
    PRIMARY KEY(viewer_id, movie_id), FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO viewers(id, username, country, joined_at)
  SELECT n, ''user_'' || n,
    CASE (n % 5) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' WHEN 3 THEN ''PL'' ELSE ''IT'' END,
    date(''2025-12-01'', ''+'' || (n % 40) || '' day'')
  FROM seq;

  INSERT INTO movies(id, title, genre, release_year) VALUES
    (1,''Skyline'',''Sci-Fi'',2020),(2,''City Lights'',''Drama'',2019),(3,''Fast Lane'',''Action'',2021),
    (4,''Deep Sea'',''Documentary'',2018),(5,''Laugh Out'',''Comedy'',2022),(6,''Old Tales'',''Drama'',2017),
    (7,''Mystery House'',''Thriller'',2023),(8,''Space Walk'',''Sci-Fi'',2024),(9,''Green Planet'',''Documentary'',2021),
    (10,''Love Story'',''Romance'',2020);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO views(id, viewer_id, movie_id, watched_at, minutes_watched)
  SELECT n, 1 + (n % 20), 1 + (n % 10),
    datetime(''2026-01-01 10:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 15) || '' days''),
    20 + (n % 9) * 10
  FROM seq;

  -- Ratings without duplicates
  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + (n % 10), 1 + (n % 5) FROM v;

  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + ((n + 3) % 10), 1 + ((n + 2) % 5) FROM v;
  ',
  '
  SELECT m.id AS movie_id,
         m.title AS title,
         COUNT(v.id) AS views_cnt
  FROM movies m
  LEFT JOIN views v ON v.movie_id = m.id
  GROUP BY m.id, m.title
  ORDER BY views_cnt DESC, movie_id ASC
  LIMIT 5;
  ',
  'ordered'
);

-- MEDIUM 2: средняя оценка по каждому фильму (если нет оценок — не показывать)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Cinema: Средняя оценка фильма',
  'Посчитать среднюю оценку по каждому фильму.',
  'Medium',
  'Для каждого фильма, у которого есть оценки, посчитайте средний рейтинг
   Ожидаемые колонки: movie_id, title, avg_rating',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE viewers (id INTEGER PRIMARY KEY, username TEXT NOT NULL, country TEXT NOT NULL, joined_at TEXT NOT NULL);
  CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT NOT NULL, genre TEXT NOT NULL, release_year INTEGER NOT NULL);
  CREATE TABLE views (id INTEGER PRIMARY KEY, viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, watched_at TEXT NOT NULL, minutes_watched INTEGER NOT NULL,
    FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  CREATE TABLE ratings (viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, rating INTEGER NOT NULL,
    PRIMARY KEY(viewer_id, movie_id), FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO viewers(id, username, country, joined_at)
  SELECT n, ''user_'' || n,
    CASE (n % 5) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' WHEN 3 THEN ''PL'' ELSE ''IT'' END,
    date(''2025-12-01'', ''+'' || (n % 40) || '' day'')
  FROM seq;

  INSERT INTO movies(id, title, genre, release_year) VALUES
    (1,''Skyline'',''Sci-Fi'',2020),(2,''City Lights'',''Drama'',2019),(3,''Fast Lane'',''Action'',2021),
    (4,''Deep Sea'',''Documentary'',2018),(5,''Laugh Out'',''Comedy'',2022),(6,''Old Tales'',''Drama'',2017),
    (7,''Mystery House'',''Thriller'',2023),(8,''Space Walk'',''Sci-Fi'',2024),(9,''Green Planet'',''Documentary'',2021),
    (10,''Love Story'',''Romance'',2020);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO views(id, viewer_id, movie_id, watched_at, minutes_watched)
  SELECT n, 1 + (n % 20), 1 + (n % 10),
    datetime(''2026-01-01 10:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 15) || '' days''),
    20 + (n % 9) * 10
  FROM seq;

  -- Ratings without duplicates
  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + (n % 10), 1 + (n % 5) FROM v;

  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + ((n + 3) % 10), 1 + ((n + 2) % 5) FROM v;
  ',
  '
  SELECT m.id AS movie_id,
         m.title AS title,
         AVG(r.rating) AS avg_rating
  FROM movies m
  JOIN ratings r ON r.movie_id = m.id
  GROUP BY m.id, m.title
  ORDER BY avg_rating DESC, movie_id ASC;
  ',
  'ordered'
);

-- MEDIUM 3: пользователи, которые смотрели хотя бы 5 разных фильмов
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Cinema: Активные зрители',
  'Найти зрителей, которые смотрели 5+ разных фильмов.',
  'Medium',
  'Найдите пользователей, которые смотрели как минимум 5 различных фильмов (по таблице views)
   Ожидаемые колонки: viewer_id, movies_cnt',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE viewers (id INTEGER PRIMARY KEY, username TEXT NOT NULL, country TEXT NOT NULL, joined_at TEXT NOT NULL);
  CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT NOT NULL, genre TEXT NOT NULL, release_year INTEGER NOT NULL);
  CREATE TABLE views (id INTEGER PRIMARY KEY, viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, watched_at TEXT NOT NULL, minutes_watched INTEGER NOT NULL,
    FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  CREATE TABLE ratings (viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, rating INTEGER NOT NULL,
    PRIMARY KEY(viewer_id, movie_id), FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO viewers(id, username, country, joined_at)
  SELECT n, ''user_'' || n,
    CASE (n % 5) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' WHEN 3 THEN ''PL'' ELSE ''IT'' END,
    date(''2025-12-01'', ''+'' || (n % 40) || '' day'')
  FROM seq;

  INSERT INTO movies(id, title, genre, release_year) VALUES
    (1,''Skyline'',''Sci-Fi'',2020),(2,''City Lights'',''Drama'',2019),(3,''Fast Lane'',''Action'',2021),
    (4,''Deep Sea'',''Documentary'',2018),(5,''Laugh Out'',''Comedy'',2022),(6,''Old Tales'',''Drama'',2017),
    (7,''Mystery House'',''Thriller'',2023),(8,''Space Walk'',''Sci-Fi'',2024),(9,''Green Planet'',''Documentary'',2021),
    (10,''Love Story'',''Romance'',2020);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO views(id, viewer_id, movie_id, watched_at, minutes_watched)
  SELECT n, 1 + (n % 20), 1 + (n % 10),
    datetime(''2026-01-01 10:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 15) || '' days''),
    20 + (n % 9) * 10
  FROM seq;

  -- Ratings without duplicates
  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + (n % 10), 1 + (n % 5) FROM v;

  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + ((n + 3) % 10), 1 + ((n + 2) % 5) FROM v;
  ',
  '
  SELECT viewer_id,
         COUNT(DISTINCT movie_id) AS movies_cnt
  FROM views
  GROUP BY viewer_id
  HAVING COUNT(DISTINCT movie_id) >= 5
  ORDER BY movies_cnt DESC, viewer_id ASC;
  ',
  'ordered'
);

-- HARD 1: среднее время просмотра по жанрам
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Cinema: Среднее время просмотра по жанрам',
  'Посчитать среднее minutes_watched по каждому жанру.',
  'Hard',
  'Объедините views и movies и посчитайте среднее время просмотра по каждому жанру
   Ожидаемые колонки: genre, avg_minutes',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE viewers (id INTEGER PRIMARY KEY, username TEXT NOT NULL, country TEXT NOT NULL, joined_at TEXT NOT NULL);
  CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT NOT NULL, genre TEXT NOT NULL, release_year INTEGER NOT NULL);
  CREATE TABLE views (id INTEGER PRIMARY KEY, viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, watched_at TEXT NOT NULL, minutes_watched INTEGER NOT NULL,
    FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  CREATE TABLE ratings (viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, rating INTEGER NOT NULL,
    PRIMARY KEY(viewer_id, movie_id), FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO viewers(id, username, country, joined_at)
  SELECT n, ''user_'' || n,
    CASE (n % 5) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' WHEN 3 THEN ''PL'' ELSE ''IT'' END,
    date(''2025-12-01'', ''+'' || (n % 40) || '' day'')
  FROM seq;

  INSERT INTO movies(id, title, genre, release_year) VALUES
    (1,''Skyline'',''Sci-Fi'',2020),(2,''City Lights'',''Drama'',2019),(3,''Fast Lane'',''Action'',2021),
    (4,''Deep Sea'',''Documentary'',2018),(5,''Laugh Out'',''Comedy'',2022),(6,''Old Tales'',''Drama'',2017),
    (7,''Mystery House'',''Thriller'',2023),(8,''Space Walk'',''Sci-Fi'',2024),(9,''Green Planet'',''Documentary'',2021),
    (10,''Love Story'',''Romance'',2020);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO views(id, viewer_id, movie_id, watched_at, minutes_watched)
  SELECT n, 1 + (n % 20), 1 + (n % 10),
    datetime(''2026-01-01 10:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 15) || '' days''),
    20 + (n % 9) * 10
  FROM seq;

  -- Ratings without duplicates
  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + (n % 10), 1 + (n % 5) FROM v;

  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + ((n + 3) % 10), 1 + ((n + 2) % 5) FROM v;
  ',
  '
  SELECT m.genre AS genre,
         AVG(v.minutes_watched) AS avg_minutes
  FROM views v
  JOIN movies m ON m.id = v.movie_id
  GROUP BY m.genre
  ORDER BY avg_minutes DESC, genre ASC;
  ',
  'ordered'
);

-- HARD 2: фильмы, которые никто не оценил
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Cinema: Фильмы без оценок',
  'Найти фильмы, у которых нет ни одной оценки.',
  'Hard',
  'Выведите фильмы, которые ни разу не встречаются в таблице ratings
   Ожидаемые колонки: movie_id, title',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE viewers (id INTEGER PRIMARY KEY, username TEXT NOT NULL, country TEXT NOT NULL, joined_at TEXT NOT NULL);
  CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT NOT NULL, genre TEXT NOT NULL, release_year INTEGER NOT NULL);
  CREATE TABLE views (id INTEGER PRIMARY KEY, viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, watched_at TEXT NOT NULL, minutes_watched INTEGER NOT NULL,
    FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  CREATE TABLE ratings (viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, rating INTEGER NOT NULL,
    PRIMARY KEY(viewer_id, movie_id), FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO viewers(id, username, country, joined_at)
  SELECT n, ''user_'' || n,
    CASE (n % 5) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' WHEN 3 THEN ''PL'' ELSE ''IT'' END,
    date(''2025-12-01'', ''+'' || (n % 40) || '' day'')
  FROM seq;

  INSERT INTO movies(id, title, genre, release_year) VALUES
    (1,''Skyline'',''Sci-Fi'',2020),(2,''City Lights'',''Drama'',2019),(3,''Fast Lane'',''Action'',2021),
    (4,''Deep Sea'',''Documentary'',2018),(5,''Laugh Out'',''Comedy'',2022),(6,''Old Tales'',''Drama'',2017),
    (7,''Mystery House'',''Thriller'',2023),(8,''Space Walk'',''Sci-Fi'',2024),(9,''Green Planet'',''Documentary'',2021),
    (10,''Love Story'',''Romance'',2020);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO views(id, viewer_id, movie_id, watched_at, minutes_watched)
  SELECT n, 1 + (n % 20), 1 + (n % 10),
    datetime(''2026-01-01 10:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 15) || '' days''),
    20 + (n % 9) * 10
  FROM seq;

  -- Ratings without duplicates
  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + (n % 10), 1 + (n % 5) FROM v;

  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + ((n + 3) % 10), 1 + ((n + 2) % 5) FROM v;
  ',
  '
  SELECT m.id AS movie_id,
         m.title AS title
  FROM movies m
  WHERE NOT EXISTS (
    SELECT 1
    FROM ratings r
    WHERE r.movie_id = m.id
  )
  ORDER BY movie_id;
  ',
  'ordered'
);

-- HARD 3: зрители, которые ставили оценку >= 4 хотя бы 3 разным фильмам
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Cinema: Любители высоких оценок',
  'Найти зрителей, которые ставили rating >= 4 минимум 3 фильмам.',
  'Hard',
  'Найдите пользователей, которые поставили оценку 4 или 5 как минимум 3 разным фильмам
   Ожидаемые колонки: viewer_id, high_rated_movies',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE viewers (id INTEGER PRIMARY KEY, username TEXT NOT NULL, country TEXT NOT NULL, joined_at TEXT NOT NULL);
  CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT NOT NULL, genre TEXT NOT NULL, release_year INTEGER NOT NULL);
  CREATE TABLE views (id INTEGER PRIMARY KEY, viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, watched_at TEXT NOT NULL, minutes_watched INTEGER NOT NULL,
    FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  CREATE TABLE ratings (viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, rating INTEGER NOT NULL,
    PRIMARY KEY(viewer_id, movie_id), FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO viewers(id, username, country, joined_at)
  SELECT n, ''user_'' || n,
    CASE (n % 5) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' WHEN 3 THEN ''PL'' ELSE ''IT'' END,
    date(''2025-12-01'', ''+'' || (n % 40) || '' day'')
  FROM seq;

  INSERT INTO movies(id, title, genre, release_year) VALUES
    (1,''Skyline'',''Sci-Fi'',2020),(2,''City Lights'',''Drama'',2019),(3,''Fast Lane'',''Action'',2021),
    (4,''Deep Sea'',''Documentary'',2018),(5,''Laugh Out'',''Comedy'',2022),(6,''Old Tales'',''Drama'',2017),
    (7,''Mystery House'',''Thriller'',2023),(8,''Space Walk'',''Sci-Fi'',2024),(9,''Green Planet'',''Documentary'',2021),
    (10,''Love Story'',''Romance'',2020);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO views(id, viewer_id, movie_id, watched_at, minutes_watched)
  SELECT n, 1 + (n % 20), 1 + (n % 10),
    datetime(''2026-01-01 10:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 15) || '' days''),
    20 + (n % 9) * 10
  FROM seq;

  -- Ratings without duplicates
  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + (n % 10), 1 + (n % 5) FROM v;

  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + ((n + 3) % 10), 1 + ((n + 2) % 5) FROM v;
  ',
  '
  SELECT viewer_id,
         COUNT(*) AS high_rated_movies
  FROM ratings
  WHERE rating >= 4
  GROUP BY viewer_id
  HAVING COUNT(*) >= 3
  ORDER BY high_rated_movies DESC, viewer_id ASC;
  ',
  'ordered'
);

-- ADVANCED 1: для каждого жанра найти фильм с максимальной средней оценкой
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Cinema: Лучший фильм в жанре по средней оценке',
  'Для каждого жанра выбрать фильм с максимальной средней оценкой.',
  'Advanced',
  'Для каждого жанра найдите фильм с максимальной средней оценкой (avg_rating)
   Если есть несколько — выберите с меньшим movie_id.
   Ожидаемые колонки: genre, movie_id, title, avg_rating',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE viewers (id INTEGER PRIMARY KEY, username TEXT NOT NULL, country TEXT NOT NULL, joined_at TEXT NOT NULL);
  CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT NOT NULL, genre TEXT NOT NULL, release_year INTEGER NOT NULL);
  CREATE TABLE views (id INTEGER PRIMARY KEY, viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, watched_at TEXT NOT NULL, minutes_watched INTEGER NOT NULL,
    FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  CREATE TABLE ratings (viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, rating INTEGER NOT NULL,
    PRIMARY KEY(viewer_id, movie_id), FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO viewers(id, username, country, joined_at)
  SELECT n, ''user_'' || n,
    CASE (n % 5) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' WHEN 3 THEN ''PL'' ELSE ''IT'' END,
    date(''2025-12-01'', ''+'' || (n % 40) || '' day'')
  FROM seq;

  INSERT INTO movies(id, title, genre, release_year) VALUES
    (1,''Skyline'',''Sci-Fi'',2020),(2,''City Lights'',''Drama'',2019),(3,''Fast Lane'',''Action'',2021),
    (4,''Deep Sea'',''Documentary'',2018),(5,''Laugh Out'',''Comedy'',2022),(6,''Old Tales'',''Drama'',2017),
    (7,''Mystery House'',''Thriller'',2023),(8,''Space Walk'',''Sci-Fi'',2024),(9,''Green Planet'',''Documentary'',2021),
    (10,''Love Story'',''Romance'',2020);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO views(id, viewer_id, movie_id, watched_at, minutes_watched)
  SELECT n, 1 + (n % 20), 1 + (n % 10),
    datetime(''2026-01-01 10:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 15) || '' days''),
    20 + (n % 9) * 10
  FROM seq;

  -- Ratings without duplicates
  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + (n % 10), 1 + (n % 5) FROM v;

  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + ((n + 3) % 10), 1 + ((n + 2) % 5) FROM v;
  ',
  '
  WITH movie_avg AS (
    SELECT m.id AS movie_id,
           m.title AS title,
           m.genre AS genre,
           AVG(r.rating) AS avg_rating
    FROM movies m
    JOIN ratings r ON r.movie_id = m.id
    GROUP BY m.id, m.title, m.genre
  ),
  ranked AS (
    SELECT genre, movie_id, title, avg_rating,
           ROW_NUMBER() OVER (PARTITION BY genre ORDER BY avg_rating DESC, movie_id ASC) AS rn
    FROM movie_avg
  )
  SELECT genre, movie_id, title, avg_rating
  FROM ranked
  WHERE rn = 1
  ORDER BY genre;
  ',
  'ordered'
);

-- ADVANCED 2: пользователи, у которых средняя оценка >= 4 и минимум 5 оценок
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Cinema: Пользователи с высокой средней оценкой',
  'Найти зрителей с avg(rating) >= 4 при 5+ оценках.',
  'Advanced',
  'Найдите пользователей, которые поставили минимум 5 оценок и их средняя оценка >= 4
   Ожидаемые колонки: viewer_id, ratings_cnt, avg_rating',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE viewers (id INTEGER PRIMARY KEY, username TEXT NOT NULL, country TEXT NOT NULL, joined_at TEXT NOT NULL);
  CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT NOT NULL, genre TEXT NOT NULL, release_year INTEGER NOT NULL);
  CREATE TABLE views (id INTEGER PRIMARY KEY, viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, watched_at TEXT NOT NULL, minutes_watched INTEGER NOT NULL,
    FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  CREATE TABLE ratings (viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, rating INTEGER NOT NULL,
    PRIMARY KEY(viewer_id, movie_id), FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO viewers(id, username, country, joined_at)
  SELECT n, ''user_'' || n,
    CASE (n % 5) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' WHEN 3 THEN ''PL'' ELSE ''IT'' END,
    date(''2025-12-01'', ''+'' || (n % 40) || '' day'')
  FROM seq;

  INSERT INTO movies(id, title, genre, release_year) VALUES
    (1,''Skyline'',''Sci-Fi'',2020),(2,''City Lights'',''Drama'',2019),(3,''Fast Lane'',''Action'',2021),
    (4,''Deep Sea'',''Documentary'',2018),(5,''Laugh Out'',''Comedy'',2022),(6,''Old Tales'',''Drama'',2017),
    (7,''Mystery House'',''Thriller'',2023),(8,''Space Walk'',''Sci-Fi'',2024),(9,''Green Planet'',''Documentary'',2021),
    (10,''Love Story'',''Romance'',2020);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO views(id, viewer_id, movie_id, watched_at, minutes_watched)
  SELECT n, 1 + (n % 20), 1 + (n % 10),
    datetime(''2026-01-01 10:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 15) || '' days''),
    20 + (n % 9) * 10
  FROM seq;

  -- Ratings without duplicates
  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + (n % 10), 1 + (n % 5) FROM v;

  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + ((n + 3) % 10), 1 + ((n + 2) % 5) FROM v;
  ',
  '
  SELECT viewer_id,
         COUNT(*) AS ratings_cnt,
         AVG(rating) AS avg_rating
  FROM ratings
  GROUP BY viewer_id
  HAVING COUNT(*) >= 5 AND AVG(rating) >= 4
  ORDER BY avg_rating DESC, viewer_id ASC;
  ',
  'ordered'
);

-- ADVANCED 3: медиана времени просмотра (minutes_watched) по всем просмотрам
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Cinema: Медиана времени просмотра',
  'Посчитать медиану minutes_watched по всем просмотрам.',
  'Advanced',
  'Посчитайте медиану minutes_watched по таблице views
   Ожидаемая колонка: median_minutes',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE viewers (id INTEGER PRIMARY KEY, username TEXT NOT NULL, country TEXT NOT NULL, joined_at TEXT NOT NULL);
  CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT NOT NULL, genre TEXT NOT NULL, release_year INTEGER NOT NULL);
  CREATE TABLE views (id INTEGER PRIMARY KEY, viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, watched_at TEXT NOT NULL, minutes_watched INTEGER NOT NULL,
    FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  CREATE TABLE ratings (viewer_id INTEGER NOT NULL, movie_id INTEGER NOT NULL, rating INTEGER NOT NULL,
    PRIMARY KEY(viewer_id, movie_id), FOREIGN KEY(viewer_id) REFERENCES viewers(id), FOREIGN KEY(movie_id) REFERENCES movies(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO viewers(id, username, country, joined_at)
  SELECT n, ''user_'' || n,
    CASE (n % 5) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' WHEN 3 THEN ''PL'' ELSE ''IT'' END,
    date(''2025-12-01'', ''+'' || (n % 40) || '' day'')
  FROM seq;

  INSERT INTO movies(id, title, genre, release_year) VALUES
    (1,''Skyline'',''Sci-Fi'',2020),(2,''City Lights'',''Drama'',2019),(3,''Fast Lane'',''Action'',2021),
    (4,''Deep Sea'',''Documentary'',2018),(5,''Laugh Out'',''Comedy'',2022),(6,''Old Tales'',''Drama'',2017),
    (7,''Mystery House'',''Thriller'',2023),(8,''Space Walk'',''Sci-Fi'',2024),(9,''Green Planet'',''Documentary'',2021),
    (10,''Love Story'',''Romance'',2020);

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO views(id, viewer_id, movie_id, watched_at, minutes_watched)
  SELECT n, 1 + (n % 20), 1 + (n % 10),
    datetime(''2026-01-01 10:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 15) || '' days''),
    20 + (n % 9) * 10
  FROM seq;

  -- Ratings without duplicates
  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + (n % 10), 1 + (n % 5) FROM v;

  WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM v WHERE n < 20)
  INSERT OR IGNORE INTO ratings(viewer_id, movie_id, rating)
  SELECT n, 1 + ((n + 3) % 10), 1 + ((n + 2) % 5) FROM v;
  ',
  '
  SELECT AVG(minutes_watched) AS median_minutes
  FROM (
    SELECT minutes_watched
    FROM views
    ORDER BY minutes_watched
    LIMIT 2 - (SELECT COUNT(*) FROM views) % 2
    OFFSET (SELECT (COUNT(*) - 1) / 2 FROM views)
  );
  ',
  'unordered'
);

-- =========================
-- DATASET: RENTALS (hosts / listings / bookings / reviews)
-- =========================

-- EASY 1: вывести объявления в Amsterdam
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Rentals: Объявления в Amsterdam',
  'Вывести все объявления (listings) в городе Amsterdam.',
  'Easy',
  'Выведите объявления, расположенные в городе Amsterdam.

Ожидаемые колонки: id, title, city, price_per_night',
  '
  PRAGMA foreign_keys = ON;

  CREATE TABLE hosts (
    id INTEGER PRIMARY KEY,
    host_name TEXT NOT NULL,
    country TEXT NOT NULL
  );

  CREATE TABLE listings (
    id INTEGER PRIMARY KEY,
    host_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    city TEXT NOT NULL,
    nightly_price INTEGER NOT NULL,
    max_guests INTEGER NOT NULL,
    FOREIGN KEY(host_id) REFERENCES hosts(id)
  );

  CREATE TABLE bookings (
    id INTEGER PRIMARY KEY,
    listing_id INTEGER NOT NULL,
    guest_name TEXT NOT NULL,
    checkin TEXT NOT NULL,
    nights INTEGER NOT NULL,
    guests INTEGER NOT NULL,
    status TEXT NOT NULL, -- confirmed | cancelled
    FOREIGN KEY(listing_id) REFERENCES listings(id)
  );

  CREATE TABLE reviews (
    id INTEGER PRIMARY KEY,
    booking_id INTEGER NOT NULL,
    rating INTEGER NOT NULL, -- 1..5
    comment TEXT,
    FOREIGN KEY(booking_id) REFERENCES bookings(id)
  );
  ',
  '
  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 10
  )
  INSERT INTO hosts(id, host_name, country)
  SELECT
    n,
    ''Host '' || n,
    CASE (n % 4)
      WHEN 0 THEN ''NL''
      WHEN 1 THEN ''DE''
      WHEN 2 THEN ''FR''
      ELSE ''ES''
    END
  FROM seq;

  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 20
  )
  INSERT INTO listings(id, host_id, title, city, nightly_price, max_guests)
  SELECT
    n,
    1 + (n % 10),
    ''Listing '' || n,
    CASE (n % 4)
      WHEN 0 THEN ''Amsterdam''
      WHEN 1 THEN ''Utrecht''
      WHEN 2 THEN ''Rotterdam''
      ELSE ''Eindhoven''
    END,
    60 + (n % 10) * 10,
    1 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 50
  )
  INSERT INTO bookings(id, listing_id, guest_name, checkin, nights, guests, status)
  SELECT
    n,
    1 + (n % 20),
    ''Guest '' || n,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day''),
    1 + (n % 7),
    1 + (n % 5),
    CASE WHEN (n % 6) = 0 THEN ''cancelled'' ELSE ''confirmed'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 35
  )
  INSERT INTO reviews(id, booking_id, rating, comment)
  SELECT
    n,
    1 + (n % 50),
    1 + (n % 5),
    CASE
      WHEN (n % 3) = 0 THEN ''ok''
      WHEN (n % 3) = 1 THEN ''good''
      ELSE ''great''
    END
  FROM seq;
  ',
  '
  SELECT id,
         title,
         city,
         nightly_price AS price_per_night
  FROM listings
  WHERE city = ''Amsterdam''
  ORDER BY id;
  ',
  'ordered'
);

-- EASY 2: посчитать количество подтвержденных бронирований
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Rentals: Подтвержденные бронирования',
  'Посчитать количество бронирований со статусом confirmed.',
  'Easy',
  'Подсчитайте количество бронирований, где status = confirmed.

Ожидаемая колонка: confirmed_cnt',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE hosts (id INTEGER PRIMARY KEY, host_name TEXT NOT NULL, country TEXT NOT NULL);
  CREATE TABLE listings (id INTEGER PRIMARY KEY, host_id INTEGER NOT NULL, title TEXT NOT NULL, city TEXT NOT NULL, nightly_price INTEGER NOT NULL, max_guests INTEGER NOT NULL,
    FOREIGN KEY(host_id) REFERENCES hosts(id));
  CREATE TABLE bookings (id INTEGER PRIMARY KEY, listing_id INTEGER NOT NULL, guest_name TEXT NOT NULL, checkin TEXT NOT NULL, nights INTEGER NOT NULL, guests INTEGER NOT NULL, status TEXT NOT NULL,
    FOREIGN KEY(listing_id) REFERENCES listings(id));
  CREATE TABLE reviews (id INTEGER PRIMARY KEY, booking_id INTEGER NOT NULL, rating INTEGER NOT NULL, comment TEXT,
    FOREIGN KEY(booking_id) REFERENCES bookings(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO hosts(id, host_name, country)
  SELECT n, ''Host '' || n,
    CASE (n % 4) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' ELSE ''ES'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO listings(id, host_id, title, city, nightly_price, max_guests)
  SELECT n, 1 + (n % 10), ''Listing '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END,
    60 + (n % 10) * 10,
    1 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO bookings(id, listing_id, guest_name, checkin, nights, guests, status)
  SELECT n, 1 + (n % 20), ''Guest '' || n,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day''),
    1 + (n % 7),
    1 + (n % 5),
    CASE WHEN (n % 6) = 0 THEN ''cancelled'' ELSE ''confirmed'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 35)
  INSERT INTO reviews(id, booking_id, rating, comment)
  SELECT n, 1 + (n % 50), 1 + (n % 5),
    CASE WHEN (n % 3) = 0 THEN ''ok'' WHEN (n % 3) = 1 THEN ''good'' ELSE ''great'' END
  FROM seq;
  ',
  '
  SELECT COUNT(*) AS confirmed_cnt
  FROM bookings
  WHERE status = ''confirmed'';
  ',
  'unordered'
);

-- EASY 3: топ-5 самых дорогих объявлений
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Rentals: Самые дорогие объявления',
  'Вывести 5 самых дорогих объявлений.',
  'Easy',
  'Выведите 5 объявлений с максимальной стоимостью за ночь.

Ожидаемые колонки: id, title, nightly_price',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE hosts (id INTEGER PRIMARY KEY, host_name TEXT NOT NULL, country TEXT NOT NULL);
  CREATE TABLE listings (id INTEGER PRIMARY KEY, host_id INTEGER NOT NULL, title TEXT NOT NULL, city TEXT NOT NULL, nightly_price INTEGER NOT NULL, max_guests INTEGER NOT NULL,
    FOREIGN KEY(host_id) REFERENCES hosts(id));
  CREATE TABLE bookings (id INTEGER PRIMARY KEY, listing_id INTEGER NOT NULL, guest_name TEXT NOT NULL, checkin TEXT NOT NULL, nights INTEGER NOT NULL, guests INTEGER NOT NULL, status TEXT NOT NULL,
    FOREIGN KEY(listing_id) REFERENCES listings(id));
  CREATE TABLE reviews (id INTEGER PRIMARY KEY, booking_id INTEGER NOT NULL, rating INTEGER NOT NULL, comment TEXT,
    FOREIGN KEY(booking_id) REFERENCES bookings(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO hosts(id, host_name, country)
  SELECT n, ''Host '' || n,
    CASE (n % 4) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' ELSE ''ES'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO listings(id, host_id, title, city, nightly_price, max_guests)
  SELECT n, 1 + (n % 10), ''Listing '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END,
    60 + (n % 10) * 10,
    1 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO bookings(id, listing_id, guest_name, checkin, nights, guests, status)
  SELECT n, 1 + (n % 20), ''Guest '' || n,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day''),
    1 + (n % 7),
    1 + (n % 5),
    CASE WHEN (n % 6) = 0 THEN ''cancelled'' ELSE ''confirmed'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 35)
  INSERT INTO reviews(id, booking_id, rating, comment)
  SELECT n, 1 + (n % 50), 1 + (n % 5),
    CASE WHEN (n % 3) = 0 THEN ''ok'' WHEN (n % 3) = 1 THEN ''good'' ELSE ''great'' END
  FROM seq;
  ',
  '
  SELECT id, title, nightly_price
  FROM listings
  ORDER BY nightly_price DESC, id ASC
  LIMIT 5;
  ',
  'ordered'
);

-- MEDIUM 1: выручка по объявлению (только confirmed)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Rentals: Выручка по объявлениям',
  'Посчитать выручку по каждому объявлению (confirmed).',
  'Medium',
  'Для каждого объявления посчитайте выручку как SUM(nights * nightly_price) по подтвержденным бронированиям.
Объявления без confirmed-бронирований должны быть в выдаче с выручкой 0.

Ожидаемые колонки: listing_id, revenue',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE hosts (id INTEGER PRIMARY KEY, host_name TEXT NOT NULL, country TEXT NOT NULL);
  CREATE TABLE listings (id INTEGER PRIMARY KEY, host_id INTEGER NOT NULL, title TEXT NOT NULL, city TEXT NOT NULL, nightly_price INTEGER NOT NULL, max_guests INTEGER NOT NULL,
    FOREIGN KEY(host_id) REFERENCES hosts(id));
  CREATE TABLE bookings (id INTEGER PRIMARY KEY, listing_id INTEGER NOT NULL, guest_name TEXT NOT NULL, checkin TEXT NOT NULL, nights INTEGER NOT NULL, guests INTEGER NOT NULL, status TEXT NOT NULL,
    FOREIGN KEY(listing_id) REFERENCES listings(id));
  CREATE TABLE reviews (id INTEGER PRIMARY KEY, booking_id INTEGER NOT NULL, rating INTEGER NOT NULL, comment TEXT,
    FOREIGN KEY(booking_id) REFERENCES bookings(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO hosts(id, host_name, country)
  SELECT n, ''Host '' || n,
    CASE (n % 4) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' ELSE ''ES'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO listings(id, host_id, title, city, nightly_price, max_guests)
  SELECT n, 1 + (n % 10), ''Listing '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END,
    60 + (n % 10) * 10,
    1 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO bookings(id, listing_id, guest_name, checkin, nights, guests, status)
  SELECT n, 1 + (n % 20), ''Guest '' || n,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day''),
    1 + (n % 7),
    1 + (n % 5),
    CASE WHEN (n % 6) = 0 THEN ''cancelled'' ELSE ''confirmed'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 35)
  INSERT INTO reviews(id, booking_id, rating, comment)
  SELECT n, 1 + (n % 50), 1 + (n % 5),
    CASE WHEN (n % 3) = 0 THEN ''ok'' WHEN (n % 3) = 1 THEN ''good'' ELSE ''great'' END
  FROM seq;
  ',
  '
  SELECT l.id AS listing_id,
         COALESCE(SUM(CASE WHEN b.status = ''confirmed'' THEN b.nights * l.nightly_price ELSE 0 END), 0) AS revenue
  FROM listings l
  LEFT JOIN bookings b ON b.listing_id = l.id
  GROUP BY l.id
  ORDER BY revenue DESC, listing_id ASC;
  ',
  'ordered'
);

-- MEDIUM 2: средний рейтинг по объявлению (только где есть reviews)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Rentals: Средний рейтинг по объявлению',
  'Посчитать средний рейтинг по каждому объявлению.',
  'Medium',
  'Посчитайте средний рейтинг по объявлениям на основе таблицы reviews.
Показывайте только объявления, у которых есть хотя бы один отзыв.

Ожидаемые колонки: listing_id, avg_rating',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE hosts (id INTEGER PRIMARY KEY, host_name TEXT NOT NULL, country TEXT NOT NULL);
  CREATE TABLE listings (id INTEGER PRIMARY KEY, host_id INTEGER NOT NULL, title TEXT NOT NULL, city TEXT NOT NULL, nightly_price INTEGER NOT NULL, max_guests INTEGER NOT NULL,
    FOREIGN KEY(host_id) REFERENCES hosts(id));
  CREATE TABLE bookings (id INTEGER PRIMARY KEY, listing_id INTEGER NOT NULL, guest_name TEXT NOT NULL, checkin TEXT NOT NULL, nights INTEGER NOT NULL, guests INTEGER NOT NULL, status TEXT NOT NULL,
    FOREIGN KEY(listing_id) REFERENCES listings(id));
  CREATE TABLE reviews (id INTEGER PRIMARY KEY, booking_id INTEGER NOT NULL, rating INTEGER NOT NULL, comment TEXT,
    FOREIGN KEY(booking_id) REFERENCES bookings(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO hosts(id, host_name, country)
  SELECT n, ''Host '' || n,
    CASE (n % 4) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' ELSE ''ES'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO listings(id, host_id, title, city, nightly_price, max_guests)
  SELECT n, 1 + (n % 10), ''Listing '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END,
    60 + (n % 10) * 10,
    1 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO bookings(id, listing_id, guest_name, checkin, nights, guests, status)
  SELECT n, 1 + (n % 20), ''Guest '' || n,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day''),
    1 + (n % 7),
    1 + (n % 5),
    CASE WHEN (n % 6) = 0 THEN ''cancelled'' ELSE ''confirmed'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 35)
  INSERT INTO reviews(id, booking_id, rating, comment)
  SELECT n, 1 + (n % 50), 1 + (n % 5),
    CASE WHEN (n % 3) = 0 THEN ''ok'' WHEN (n % 3) = 1 THEN ''good'' ELSE ''great'' END
  FROM seq;
  ',
  '
  SELECT b.listing_id AS listing_id,
         AVG(r.rating) AS avg_rating
  FROM reviews r
  JOIN bookings b ON b.id = r.booking_id
  GROUP BY b.listing_id
  ORDER BY avg_rating DESC, listing_id ASC;
  ',
  'ordered'
);

-- MEDIUM 3: объявления без confirmed бронирований
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Rentals: Объявления без confirmed бронирований',
  'Найти объявления без подтвержденных бронирований.',
  'Medium',
  'Выведите объявления, у которых нет ни одного бронирования со статусом confirmed.

Ожидаемые колонки: listing_id, title',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE hosts (id INTEGER PRIMARY KEY, host_name TEXT NOT NULL, country TEXT NOT NULL);
  CREATE TABLE listings (id INTEGER PRIMARY KEY, host_id INTEGER NOT NULL, title TEXT NOT NULL, city TEXT NOT NULL, nightly_price INTEGER NOT NULL, max_guests INTEGER NOT NULL,
    FOREIGN KEY(host_id) REFERENCES hosts(id));
  CREATE TABLE bookings (id INTEGER PRIMARY KEY, listing_id INTEGER NOT NULL, guest_name TEXT NOT NULL, checkin TEXT NOT NULL, nights INTEGER NOT NULL, guests INTEGER NOT NULL, status TEXT NOT NULL,
    FOREIGN KEY(listing_id) REFERENCES listings(id));
  CREATE TABLE reviews (id INTEGER PRIMARY KEY, booking_id INTEGER NOT NULL, rating INTEGER NOT NULL, comment TEXT,
    FOREIGN KEY(booking_id) REFERENCES bookings(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO hosts(id, host_name, country)
  SELECT n, ''Host '' || n,
    CASE (n % 4) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' ELSE ''ES'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO listings(id, host_id, title, city, nightly_price, max_guests)
  SELECT n, 1 + (n % 10), ''Listing '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END,
    60 + (n % 10) * 10,
    1 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO bookings(id, listing_id, guest_name, checkin, nights, guests, status)
  SELECT n, 1 + (n % 20), ''Guest '' || n,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day''),
    1 + (n % 7),
    1 + (n % 5),
    CASE WHEN (n % 6) = 0 THEN ''cancelled'' ELSE ''confirmed'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 35)
  INSERT INTO reviews(id, booking_id, rating, comment)
  SELECT n, 1 + (n % 50), 1 + (n % 5),
    CASE WHEN (n % 3) = 0 THEN ''ok'' WHEN (n % 3) = 1 THEN ''good'' ELSE ''great'' END
  FROM seq;
  ',
  '
  SELECT l.id AS listing_id,
         l.title AS title
  FROM listings l
  WHERE NOT EXISTS (
    SELECT 1
    FROM bookings b
    WHERE b.listing_id = l.id AND b.status = ''confirmed''
  )
  ORDER BY listing_id;
  ',
  'ordered'
);

-- HARD 1: топ-5 гостей по суммарным ночам (только confirmed)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Rentals: Топ гостей по ночам',
  'Найти 5 гостей с максимальной суммой nights (confirmed).',
  'Hard',
  'Посчитайте суммарное количество ночей (SUM(nights)) по каждому гостю для confirmed бронирований.
Выведите топ-5.

Ожидаемые колонки: guest_name, nights_total',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE hosts (id INTEGER PRIMARY KEY, host_name TEXT NOT NULL, country TEXT NOT NULL);
  CREATE TABLE listings (id INTEGER PRIMARY KEY, host_id INTEGER NOT NULL, title TEXT NOT NULL, city TEXT NOT NULL, nightly_price INTEGER NOT NULL, max_guests INTEGER NOT NULL,
    FOREIGN KEY(host_id) REFERENCES hosts(id));
  CREATE TABLE bookings (id INTEGER PRIMARY KEY, listing_id INTEGER NOT NULL, guest_name TEXT NOT NULL, checkin TEXT NOT NULL, nights INTEGER NOT NULL, guests INTEGER NOT NULL, status TEXT NOT NULL,
    FOREIGN KEY(listing_id) REFERENCES listings(id));
  CREATE TABLE reviews (id INTEGER PRIMARY KEY, booking_id INTEGER NOT NULL, rating INTEGER NOT NULL, comment TEXT,
    FOREIGN KEY(booking_id) REFERENCES bookings(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO hosts(id, host_name, country)
  SELECT n, ''Host '' || n,
    CASE (n % 4) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' ELSE ''ES'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO listings(id, host_id, title, city, nightly_price, max_guests)
  SELECT n, 1 + (n % 10), ''Listing '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END,
    60 + (n % 10) * 10,
    1 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO bookings(id, listing_id, guest_name, checkin, nights, guests, status)
  SELECT n, 1 + (n % 20), ''Guest '' || n,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day''),
    1 + (n % 7),
    1 + (n % 5),
    CASE WHEN (n % 6) = 0 THEN ''cancelled'' ELSE ''confirmed'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 35)
  INSERT INTO reviews(id, booking_id, rating, comment)
  SELECT n, 1 + (n % 50), 1 + (n % 5),
    CASE WHEN (n % 3) = 0 THEN ''ok'' WHEN (n % 3) = 1 THEN ''good'' ELSE ''great'' END
  FROM seq;
  ',
  '
  SELECT guest_name,
         SUM(nights) AS nights_total
  FROM bookings
  WHERE status = ''confirmed''
  GROUP BY guest_name
  ORDER BY nights_total DESC, guest_name ASC
  LIMIT 5;
  ',
  'ordered'
);

-- HARD 2: города с высокой средней ценой
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Rentals: Города с высокой средней ценой',
  'Найти города, где средняя цена за ночь >= 110.',
  'Hard',
  'Посчитайте среднюю цену за ночь (AVG(nightly_price)) по каждому городу и выведите только города, где средняя цена >= 110.

Ожидаемые колонки: city, avg_price',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE hosts (id INTEGER PRIMARY KEY, host_name TEXT NOT NULL, country TEXT NOT NULL);
  CREATE TABLE listings (id INTEGER PRIMARY KEY, host_id INTEGER NOT NULL, title TEXT NOT NULL, city TEXT NOT NULL, nightly_price INTEGER NOT NULL, max_guests INTEGER NOT NULL,
    FOREIGN KEY(host_id) REFERENCES hosts(id));
  CREATE TABLE bookings (id INTEGER PRIMARY KEY, listing_id INTEGER NOT NULL, guest_name TEXT NOT NULL, checkin TEXT NOT NULL, nights INTEGER NOT NULL, guests INTEGER NOT NULL, status TEXT NOT NULL,
    FOREIGN KEY(listing_id) REFERENCES listings(id));
  CREATE TABLE reviews (id INTEGER PRIMARY KEY, booking_id INTEGER NOT NULL, rating INTEGER NOT NULL, comment TEXT,
    FOREIGN KEY(booking_id) REFERENCES bookings(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO hosts(id, host_name, country)
  SELECT n, ''Host '' || n,
    CASE (n % 4) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' ELSE ''ES'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO listings(id, host_id, title, city, nightly_price, max_guests)
  SELECT n, 1 + (n % 10), ''Listing '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END,
    60 + (n % 10) * 10,
    1 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO bookings(id, listing_id, guest_name, checkin, nights, guests, status)
  SELECT n, 1 + (n % 20), ''Guest '' || n,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day''),
    1 + (n % 7),
    1 + (n % 5),
    CASE WHEN (n % 6) = 0 THEN ''cancelled'' ELSE ''confirmed'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 35)
  INSERT INTO reviews(id, booking_id, rating, comment)
  SELECT n, 1 + (n % 50), 1 + (n % 5),
    CASE WHEN (n % 3) = 0 THEN ''ok'' WHEN (n % 3) = 1 THEN ''good'' ELSE ''great'' END
  FROM seq;
  ',
  '
  SELECT city,
         AVG(nightly_price) AS avg_price
  FROM listings
  GROUP BY city
  HAVING AVG(nightly_price) >= 110
  ORDER BY avg_price DESC, city ASC;
  ',
  'ordered'
);

-- HARD 3: объявления с выручкой выше средней
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Rentals: Выручка выше средней',
  'Найти объявления, чья выручка выше средней по всем объявлениям.',
  'Hard',
  'Сначала посчитайте выручку (SUM(nights * nightly_price)) по каждому объявлению по confirmed бронированиям.
Затем выведите те объявления, у которых выручка выше средней по всем объявлениям.

Ожидаемые колонки: listing_id, revenue',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE hosts (id INTEGER PRIMARY KEY, host_name TEXT NOT NULL, country TEXT NOT NULL);
  CREATE TABLE listings (id INTEGER PRIMARY KEY, host_id INTEGER NOT NULL, title TEXT NOT NULL, city TEXT NOT NULL, nightly_price INTEGER NOT NULL, max_guests INTEGER NOT NULL,
    FOREIGN KEY(host_id) REFERENCES hosts(id));
  CREATE TABLE bookings (id INTEGER PRIMARY KEY, listing_id INTEGER NOT NULL, guest_name TEXT NOT NULL, checkin TEXT NOT NULL, nights INTEGER NOT NULL, guests INTEGER NOT NULL, status TEXT NOT NULL,
    FOREIGN KEY(listing_id) REFERENCES listings(id));
  CREATE TABLE reviews (id INTEGER PRIMARY KEY, booking_id INTEGER NOT NULL, rating INTEGER NOT NULL, comment TEXT,
    FOREIGN KEY(booking_id) REFERENCES bookings(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO hosts(id, host_name, country)
  SELECT n, ''Host '' || n,
    CASE (n % 4) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' ELSE ''ES'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO listings(id, host_id, title, city, nightly_price, max_guests)
  SELECT n, 1 + (n % 10), ''Listing '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END,
    60 + (n % 10) * 10,
    1 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO bookings(id, listing_id, guest_name, checkin, nights, guests, status)
  SELECT n, 1 + (n % 20), ''Guest '' || n,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day''),
    1 + (n % 7),
    1 + (n % 5),
    CASE WHEN (n % 6) = 0 THEN ''cancelled'' ELSE ''confirmed'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 35)
  INSERT INTO reviews(id, booking_id, rating, comment)
  SELECT n, 1 + (n % 50), 1 + (n % 5),
    CASE WHEN (n % 3) = 0 THEN ''ok'' WHEN (n % 3) = 1 THEN ''good'' ELSE ''great'' END
  FROM seq;
  ',
  '
  WITH per_listing AS (
    SELECT l.id AS listing_id,
           COALESCE(SUM(CASE WHEN b.status = ''confirmed'' THEN b.nights * l.nightly_price ELSE 0 END), 0) AS revenue
    FROM listings l
    LEFT JOIN bookings b ON b.listing_id = l.id
    GROUP BY l.id
  )
  SELECT listing_id, revenue
  FROM per_listing
  WHERE revenue > (SELECT AVG(revenue) FROM per_listing)
  ORDER BY revenue DESC, listing_id ASC;
  ',
  'ordered'
);

-- ADVANCED 1: лучший хост по выручке (confirmed)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Rentals: Лучший хост по выручке',
  'Найти хоста с максимальной выручкой (confirmed).',
  'Advanced',
  'Посчитайте выручку каждого хоста по подтвержденным бронированиям (SUM(nights * nightly_price)).
Выведите хоста с максимальной выручкой.
Если несколько — выберите с меньшим host_id.

Ожидаемые колонки: host_id, revenue',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE hosts (id INTEGER PRIMARY KEY, host_name TEXT NOT NULL, country TEXT NOT NULL);
  CREATE TABLE listings (id INTEGER PRIMARY KEY, host_id INTEGER NOT NULL, title TEXT NOT NULL, city TEXT NOT NULL, nightly_price INTEGER NOT NULL, max_guests INTEGER NOT NULL,
    FOREIGN KEY(host_id) REFERENCES hosts(id));
  CREATE TABLE bookings (id INTEGER PRIMARY KEY, listing_id INTEGER NOT NULL, guest_name TEXT NOT NULL, checkin TEXT NOT NULL, nights INTEGER NOT NULL, guests INTEGER NOT NULL, status TEXT NOT NULL,
    FOREIGN KEY(listing_id) REFERENCES listings(id));
  CREATE TABLE reviews (id INTEGER PRIMARY KEY, booking_id INTEGER NOT NULL, rating INTEGER NOT NULL, comment TEXT,
    FOREIGN KEY(booking_id) REFERENCES bookings(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO hosts(id, host_name, country)
  SELECT n, ''Host '' || n,
    CASE (n % 4) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' ELSE ''ES'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO listings(id, host_id, title, city, nightly_price, max_guests)
  SELECT n, 1 + (n % 10), ''Listing '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END,
    60 + (n % 10) * 10,
    1 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO bookings(id, listing_id, guest_name, checkin, nights, guests, status)
  SELECT n, 1 + (n % 20), ''Guest '' || n,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day''),
    1 + (n % 7),
    1 + (n % 5),
    CASE WHEN (n % 6) = 0 THEN ''cancelled'' ELSE ''confirmed'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 35)
  INSERT INTO reviews(id, booking_id, rating, comment)
  SELECT n, 1 + (n % 50), 1 + (n % 5),
    CASE WHEN (n % 3) = 0 THEN ''ok'' WHEN (n % 3) = 1 THEN ''good'' ELSE ''great'' END
  FROM seq;
  ',
  '
  WITH per_host AS (
    SELECT h.id AS host_id,
           COALESCE(SUM(CASE WHEN b.status = ''confirmed'' THEN b.nights * l.nightly_price ELSE 0 END), 0) AS revenue
    FROM hosts h
    JOIN listings l ON l.host_id = h.id
    LEFT JOIN bookings b ON b.listing_id = l.id
    GROUP BY h.id
  )
  SELECT host_id, revenue
  FROM per_host
  ORDER BY revenue DESC, host_id ASC
  LIMIT 1;
  ',
  'ordered'
);

-- ADVANCED 2: доля отмен по городам
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Rentals: Доля отмен по городам',
  'Посчитать долю cancelled бронирований по каждому городу.',
  'Advanced',
  'Для каждого города посчитайте долю отмен: cancelled_cnt / total_cnt.
Считать по таблице bookings, связав с listings.

Ожидаемые колонки: city, cancelled_share',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE hosts (id INTEGER PRIMARY KEY, host_name TEXT NOT NULL, country TEXT NOT NULL);
  CREATE TABLE listings (id INTEGER PRIMARY KEY, host_id INTEGER NOT NULL, title TEXT NOT NULL, city TEXT NOT NULL, nightly_price INTEGER NOT NULL, max_guests INTEGER NOT NULL,
    FOREIGN KEY(host_id) REFERENCES hosts(id));
  CREATE TABLE bookings (id INTEGER PRIMARY KEY, listing_id INTEGER NOT NULL, guest_name TEXT NOT NULL, checkin TEXT NOT NULL, nights INTEGER NOT NULL, guests INTEGER NOT NULL, status TEXT NOT NULL,
    FOREIGN KEY(listing_id) REFERENCES listings(id));
  CREATE TABLE reviews (id INTEGER PRIMARY KEY, booking_id INTEGER NOT NULL, rating INTEGER NOT NULL, comment TEXT,
    FOREIGN KEY(booking_id) REFERENCES bookings(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO hosts(id, host_name, country)
  SELECT n, ''Host '' || n,
    CASE (n % 4) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' ELSE ''ES'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO listings(id, host_id, title, city, nightly_price, max_guests)
  SELECT n, 1 + (n % 10), ''Listing '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END,
    60 + (n % 10) * 10,
    1 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO bookings(id, listing_id, guest_name, checkin, nights, guests, status)
  SELECT n, 1 + (n % 20), ''Guest '' || n,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day''),
    1 + (n % 7),
    1 + (n % 5),
    CASE WHEN (n % 6) = 0 THEN ''cancelled'' ELSE ''confirmed'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 35)
  INSERT INTO reviews(id, booking_id, rating, comment)
  SELECT n, 1 + (n % 50), 1 + (n % 5),
    CASE WHEN (n % 3) = 0 THEN ''ok'' WHEN (n % 3) = 1 THEN ''good'' ELSE ''great'' END
  FROM seq;
  ',
  '
  SELECT l.city AS city,
         (1.0 * SUM(CASE WHEN b.status = ''cancelled'' THEN 1 ELSE 0 END)) / COUNT(*) AS cancelled_share
  FROM bookings b
  JOIN listings l ON l.id = b.listing_id
  GROUP BY l.city
  ORDER BY cancelled_share DESC, city ASC;
  ',
  'ordered'
);

-- ADVANCED 3: медиана цены за ночь по всем объявлениям
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Rentals: Медиана цены за ночь',
  'Посчитать медиану nightly_price по таблице listings.',
  'Advanced',
  'Посчитайте медиану nightly_price по всем объявлениям.

Ожидаемая колонка: median_price',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE hosts (id INTEGER PRIMARY KEY, host_name TEXT NOT NULL, country TEXT NOT NULL);
  CREATE TABLE listings (id INTEGER PRIMARY KEY, host_id INTEGER NOT NULL, title TEXT NOT NULL, city TEXT NOT NULL, nightly_price INTEGER NOT NULL, max_guests INTEGER NOT NULL,
    FOREIGN KEY(host_id) REFERENCES hosts(id));
  CREATE TABLE bookings (id INTEGER PRIMARY KEY, listing_id INTEGER NOT NULL, guest_name TEXT NOT NULL, checkin TEXT NOT NULL, nights INTEGER NOT NULL, guests INTEGER NOT NULL, status TEXT NOT NULL,
    FOREIGN KEY(listing_id) REFERENCES listings(id));
  CREATE TABLE reviews (id INTEGER PRIMARY KEY, booking_id INTEGER NOT NULL, rating INTEGER NOT NULL, comment TEXT,
    FOREIGN KEY(booking_id) REFERENCES bookings(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO hosts(id, host_name, country)
  SELECT n, ''Host '' || n,
    CASE (n % 4) WHEN 0 THEN ''NL'' WHEN 1 THEN ''DE'' WHEN 2 THEN ''FR'' ELSE ''ES'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20)
  INSERT INTO listings(id, host_id, title, city, nightly_price, max_guests)
  SELECT n, 1 + (n % 10), ''Listing '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END,
    60 + (n % 10) * 10,
    1 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO bookings(id, listing_id, guest_name, checkin, nights, guests, status)
  SELECT n, 1 + (n % 20), ''Guest '' || n,
    date(''2026-01-01'', ''+'' || (n % 28) || '' day''),
    1 + (n % 7),
    1 + (n % 5),
    CASE WHEN (n % 6) = 0 THEN ''cancelled'' ELSE ''confirmed'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 35)
  INSERT INTO reviews(id, booking_id, rating, comment)
  SELECT n, 1 + (n % 50), 1 + (n % 5),
    CASE WHEN (n % 3) = 0 THEN ''ok'' WHEN (n % 3) = 1 THEN ''good'' ELSE ''great'' END
  FROM seq;
  ',
  '
  SELECT AVG(nightly_price) AS median_price
  FROM (
    SELECT nightly_price
    FROM listings
    ORDER BY nightly_price
    LIMIT 2 - (SELECT COUNT(*) FROM listings) % 2
    OFFSET (SELECT (COUNT(*) - 1) / 2 FROM listings)
  );
  ',
  'unordered'
);



-- =========================
-- DATASET: FOOD DELIVERY (customers / restaurants / menu_items / orders / order_items)
-- =========================

-- EASY 1: рестораны в Amsterdam
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Delivery: Рестораны в Amsterdam',
  'Вывести рестораны, которые находятся в Amsterdam.',
  'Easy',
  'Выведите все рестораны, у которых city = Amsterdam.

Ожидаемые колонки: id, name, city',
  '
  PRAGMA foreign_keys = ON;

  CREATE TABLE customers (
    id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    city TEXT NOT NULL
  );

  CREATE TABLE restaurants (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    city TEXT NOT NULL
  );

  CREATE TABLE menu_items (
    id INTEGER PRIMARY KEY,
    restaurant_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    price INTEGER NOT NULL,
    category TEXT NOT NULL,
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id)
  );

  CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    restaurant_id INTEGER NOT NULL,
    ordered_at TEXT NOT NULL,
    status TEXT NOT NULL, -- delivered | cancelled
    delivery_fee INTEGER NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id),
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id)
  );

  CREATE TABLE order_items (
    id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    menu_item_id INTEGER NOT NULL,
    qty INTEGER NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id),
    FOREIGN KEY(menu_item_id) REFERENCES menu_items(id)
  );
  ',
  '
  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 15
  )
  INSERT INTO customers(id, full_name, city)
  SELECT
    n,
    ''Customer '' || n,
    CASE (n % 4)
      WHEN 0 THEN ''Amsterdam''
      WHEN 1 THEN ''Utrecht''
      WHEN 2 THEN ''Rotterdam''
      ELSE ''Eindhoven''
    END
  FROM seq;

  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 10
  )
  INSERT INTO restaurants(id, name, city)
  SELECT
    n,
    ''Restaurant '' || n,
    CASE (n % 4)
      WHEN 0 THEN ''Amsterdam''
      WHEN 1 THEN ''Utrecht''
      WHEN 2 THEN ''Rotterdam''
      ELSE ''Eindhoven''
    END
  FROM seq;

  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 30
  )
  INSERT INTO menu_items(id, restaurant_id, item_name, price, category)
  SELECT
    n,
    1 + (n % 10),
    ''Item '' || n,
    5 + (n % 16) * 2,
    CASE (n % 5)
      WHEN 0 THEN ''Pizza''
      WHEN 1 THEN ''Burger''
      WHEN 2 THEN ''Salad''
      WHEN 3 THEN ''Sushi''
      ELSE ''Dessert''
    END
  FROM seq;

  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 50
  )
  INSERT INTO orders(id, customer_id, restaurant_id, ordered_at, status, delivery_fee)
  SELECT
    n,
    1 + (n % 15),
    1 + (n % 10),
    datetime(''2026-01-01 12:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 14) || '' days''),
    CASE WHEN (n % 7) = 0 THEN ''cancelled'' ELSE ''delivered'' END,
    2 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n+1 FROM seq WHERE n < 80
  )
  INSERT INTO order_items(id, order_id, menu_item_id, qty)
  SELECT
    n,
    1 + (n % 50),
    1 + (n % 30),
    1 + (n % 3)
  FROM seq;
  ',
  '
  SELECT id, name, city
  FROM restaurants
  WHERE city = ''Amsterdam''
  ORDER BY id;
  ',
  'ordered'
);

-- EASY 2: количество заказов всего
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Delivery: Количество заказов',
  'Посчитать общее количество заказов.',
  'Easy',
  'Подсчитайте количество строк в таблице orders.

Ожидаемая колонка: orders_cnt',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE customers (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE restaurants (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE menu_items (id INTEGER PRIMARY KEY, restaurant_id INTEGER NOT NULL, item_name TEXT NOT NULL, price INTEGER NOT NULL, category TEXT NOT NULL,
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL, restaurant_id INTEGER NOT NULL, ordered_at TEXT NOT NULL, status TEXT NOT NULL, delivery_fee INTEGER NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id), FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE order_items (id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, menu_item_id INTEGER NOT NULL, qty INTEGER NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(menu_item_id) REFERENCES menu_items(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 15)
  INSERT INTO customers(id, full_name, city)
  SELECT n, ''Customer '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO restaurants(id, name, city)
  SELECT n, ''Restaurant '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 30)
  INSERT INTO menu_items(id, restaurant_id, item_name, price, category)
  SELECT n, 1 + (n % 10), ''Item '' || n,
    5 + (n % 16) * 2,
    CASE (n % 5) WHEN 0 THEN ''Pizza'' WHEN 1 THEN ''Burger'' WHEN 2 THEN ''Salad'' WHEN 3 THEN ''Sushi'' ELSE ''Dessert'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, customer_id, restaurant_id, ordered_at, status, delivery_fee)
  SELECT n, 1 + (n % 15), 1 + (n % 10),
    datetime(''2026-01-01 12:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 14) || '' days''),
    CASE WHEN (n % 7) = 0 THEN ''cancelled'' ELSE ''delivered'' END,
    2 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 80)
  INSERT INTO order_items(id, order_id, menu_item_id, qty)
  SELECT n, 1 + (n % 50), 1 + (n % 30), 1 + (n % 3)
  FROM seq;
  ',
  '
  SELECT COUNT(*) AS orders_cnt
  FROM orders;
  ',
  'unordered'
);

-- EASY 3: блюда дороже 25
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Delivery: Дорогие блюда',
  'Найти блюда с ценой больше 25.',
  'Easy',
  'Выведите блюда из menu_items, у которых price > 25.

Ожидаемые колонки: id, item_name, price',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE customers (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE restaurants (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE menu_items (id INTEGER PRIMARY KEY, restaurant_id INTEGER NOT NULL, item_name TEXT NOT NULL, price INTEGER NOT NULL, category TEXT NOT NULL,
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL, restaurant_id INTEGER NOT NULL, ordered_at TEXT NOT NULL, status TEXT NOT NULL, delivery_fee INTEGER NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id), FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE order_items (id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, menu_item_id INTEGER NOT NULL, qty INTEGER NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(menu_item_id) REFERENCES menu_items(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 15)
  INSERT INTO customers(id, full_name, city)
  SELECT n, ''Customer '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO restaurants(id, name, city)
  SELECT n, ''Restaurant '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 30)
  INSERT INTO menu_items(id, restaurant_id, item_name, price, category)
  SELECT n, 1 + (n % 10), ''Item '' || n,
    5 + (n % 16) * 2,
    CASE (n % 5) WHEN 0 THEN ''Pizza'' WHEN 1 THEN ''Burger'' WHEN 2 THEN ''Salad'' WHEN 3 THEN ''Sushi'' ELSE ''Dessert'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, customer_id, restaurant_id, ordered_at, status, delivery_fee)
  SELECT n, 1 + (n % 15), 1 + (n % 10),
    datetime(''2026-01-01 12:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 14) || '' days''),
    CASE WHEN (n % 7) = 0 THEN ''cancelled'' ELSE ''delivered'' END,
    2 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 80)
  INSERT INTO order_items(id, order_id, menu_item_id, qty)
  SELECT n, 1 + (n % 50), 1 + (n % 30), 1 + (n % 3)
  FROM seq;
  ',
  '
  SELECT id, item_name, price
  FROM menu_items
  WHERE price > 25
  ORDER BY price DESC, id ASC;
  ',
  'ordered'
);

-- MEDIUM 1: количество доставленных заказов по ресторанам
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Delivery: Доставленные заказы по ресторанам',
  'Посчитать количество delivered заказов у каждого ресторана.',
  'Medium',
  'Для каждого ресторана посчитайте количество заказов со статусом delivered.
Рестораны без delivered-заказов должны быть в выдаче с 0.

Ожидаемые колонки: restaurant_id, delivered_cnt',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE customers (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE restaurants (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE menu_items (id INTEGER PRIMARY KEY, restaurant_id INTEGER NOT NULL, item_name TEXT NOT NULL, price INTEGER NOT NULL, category TEXT NOT NULL,
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL, restaurant_id INTEGER NOT NULL, ordered_at TEXT NOT NULL, status TEXT NOT NULL, delivery_fee INTEGER NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id), FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE order_items (id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, menu_item_id INTEGER NOT NULL, qty INTEGER NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(menu_item_id) REFERENCES menu_items(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 15)
  INSERT INTO customers(id, full_name, city)
  SELECT n, ''Customer '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO restaurants(id, name, city)
  SELECT n, ''Restaurant '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 30)
  INSERT INTO menu_items(id, restaurant_id, item_name, price, category)
  SELECT n, 1 + (n % 10), ''Item '' || n,
    5 + (n % 16) * 2,
    CASE (n % 5) WHEN 0 THEN ''Pizza'' WHEN 1 THEN ''Burger'' WHEN 2 THEN ''Salad'' WHEN 3 THEN ''Sushi'' ELSE ''Dessert'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, customer_id, restaurant_id, ordered_at, status, delivery_fee)
  SELECT n, 1 + (n % 15), 1 + (n % 10),
    datetime(''2026-01-01 12:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 14) || '' days''),
    CASE WHEN (n % 7) = 0 THEN ''cancelled'' ELSE ''delivered'' END,
    2 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 80)
  INSERT INTO order_items(id, order_id, menu_item_id, qty)
  SELECT n, 1 + (n % 50), 1 + (n % 30), 1 + (n % 3)
  FROM seq;
  ',
  '
  SELECT r.id AS restaurant_id,
         COALESCE(SUM(CASE WHEN o.status = ''delivered'' THEN 1 ELSE 0 END), 0) AS delivered_cnt
  FROM restaurants r
  LEFT JOIN orders o ON o.restaurant_id = r.id
  GROUP BY r.id
  ORDER BY delivered_cnt DESC, restaurant_id ASC;
  ',
  'ordered'
);

-- MEDIUM 2: выручка заказа (items + delivery_fee), только delivered
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Delivery: Выручка по заказам',
  'Посчитать сумму заказа (items + delivery_fee) для delivered.',
  'Medium',
  'Для каждого delivered заказа посчитайте сумму:
SUM(qty * price) + delivery_fee.

Ожидаемые колонки: order_id, total_amount',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE customers (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE restaurants (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE menu_items (id INTEGER PRIMARY KEY, restaurant_id INTEGER NOT NULL, item_name TEXT NOT NULL, price INTEGER NOT NULL, category TEXT NOT NULL,
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL, restaurant_id INTEGER NOT NULL, ordered_at TEXT NOT NULL, status TEXT NOT NULL, delivery_fee INTEGER NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id), FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE order_items (id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, menu_item_id INTEGER NOT NULL, qty INTEGER NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(menu_item_id) REFERENCES menu_items(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 15)
  INSERT INTO customers(id, full_name, city)
  SELECT n, ''Customer '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO restaurants(id, name, city)
  SELECT n, ''Restaurant '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 30)
  INSERT INTO menu_items(id, restaurant_id, item_name, price, category)
  SELECT n, 1 + (n % 10), ''Item '' || n,
    5 + (n % 16) * 2,
    CASE (n % 5) WHEN 0 THEN ''Pizza'' WHEN 1 THEN ''Burger'' WHEN 2 THEN ''Salad'' WHEN 3 THEN ''Sushi'' ELSE ''Dessert'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, customer_id, restaurant_id, ordered_at, status, delivery_fee)
  SELECT n, 1 + (n % 15), 1 + (n % 10),
    datetime(''2026-01-01 12:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 14) || '' days''),
    CASE WHEN (n % 7) = 0 THEN ''cancelled'' ELSE ''delivered'' END,
    2 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 80)
  INSERT INTO order_items(id, order_id, menu_item_id, qty)
  SELECT n, 1 + (n % 50), 1 + (n % 30), 1 + (n % 3)
  FROM seq;
  ',
  '
  SELECT o.id AS order_id,
         (SUM(oi.qty * mi.price) + o.delivery_fee) AS total_amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.id
  JOIN menu_items mi ON mi.id = oi.menu_item_id
  WHERE o.status = ''delivered''
  GROUP BY o.id, o.delivery_fee
  ORDER BY total_amount DESC, order_id ASC;
  ',
  'ordered'
);

-- MEDIUM 3: клиенты без delivered заказов
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Delivery: Клиенты без доставок',
  'Найти клиентов, у которых нет ни одного delivered заказа.',
  'Medium',
  'Выведите клиентов, у которых нет заказов со статусом delivered.

Ожидаемые колонки: customer_id, full_name',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE customers (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE restaurants (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE menu_items (id INTEGER PRIMARY KEY, restaurant_id INTEGER NOT NULL, item_name TEXT NOT NULL, price INTEGER NOT NULL, category TEXT NOT NULL,
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL, restaurant_id INTEGER NOT NULL, ordered_at TEXT NOT NULL, status TEXT NOT NULL, delivery_fee INTEGER NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id), FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE order_items (id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, menu_item_id INTEGER NOT NULL, qty INTEGER NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(menu_item_id) REFERENCES menu_items(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 15)
  INSERT INTO customers(id, full_name, city)
  SELECT n, ''Customer '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO restaurants(id, name, city)
  SELECT n, ''Restaurant '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 30)
  INSERT INTO menu_items(id, restaurant_id, item_name, price, category)
  SELECT n, 1 + (n % 10), ''Item '' || n,
    5 + (n % 16) * 2,
    CASE (n % 5) WHEN 0 THEN ''Pizza'' WHEN 1 THEN ''Burger'' WHEN 2 THEN ''Salad'' WHEN 3 THEN ''Sushi'' ELSE ''Dessert'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, customer_id, restaurant_id, ordered_at, status, delivery_fee)
  SELECT n, 1 + (n % 15), 1 + (n % 10),
    datetime(''2026-01-01 12:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 14) || '' days''),
    CASE WHEN (n % 7) = 0 THEN ''cancelled'' ELSE ''delivered'' END,
    2 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 80)
  INSERT INTO order_items(id, order_id, menu_item_id, qty)
  SELECT n, 1 + (n % 50), 1 + (n % 30), 1 + (n % 3)
  FROM seq;
  ',
  '
  SELECT c.id AS customer_id,
         c.full_name AS full_name
  FROM customers c
  WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id AND o.status = ''delivered''
  )
  ORDER BY customer_id;
  ',
  'ordered'
);

-- HARD 1: топ-5 блюд по выручке (delivered)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Delivery: Топ блюд по выручке',
  'Найти 5 блюд с максимальной выручкой по delivered заказам.',
  'Hard',
  'Посчитайте выручку каждого блюда как SUM(qty * price) по delivered заказам.
Выведите топ-5.

Ожидаемые колонки: menu_item_id, item_name, revenue',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE customers (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE restaurants (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE menu_items (id INTEGER PRIMARY KEY, restaurant_id INTEGER NOT NULL, item_name TEXT NOT NULL, price INTEGER NOT NULL, category TEXT NOT NULL,
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL, restaurant_id INTEGER NOT NULL, ordered_at TEXT NOT NULL, status TEXT NOT NULL, delivery_fee INTEGER NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id), FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE order_items (id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, menu_item_id INTEGER NOT NULL, qty INTEGER NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(menu_item_id) REFERENCES menu_items(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 15)
  INSERT INTO customers(id, full_name, city)
  SELECT n, ''Customer '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO restaurants(id, name, city)
  SELECT n, ''Restaurant '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 30)
  INSERT INTO menu_items(id, restaurant_id, item_name, price, category)
  SELECT n, 1 + (n % 10), ''Item '' || n,
    5 + (n % 16) * 2,
    CASE (n % 5) WHEN 0 THEN ''Pizza'' WHEN 1 THEN ''Burger'' WHEN 2 THEN ''Salad'' WHEN 3 THEN ''Sushi'' ELSE ''Dessert'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, customer_id, restaurant_id, ordered_at, status, delivery_fee)
  SELECT n, 1 + (n % 15), 1 + (n % 10),
    datetime(''2026-01-01 12:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 14) || '' days''),
    CASE WHEN (n % 7) = 0 THEN ''cancelled'' ELSE ''delivered'' END,
    2 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 80)
  INSERT INTO order_items(id, order_id, menu_item_id, qty)
  SELECT n, 1 + (n % 50), 1 + (n % 30), 1 + (n % 3)
  FROM seq;
  ',
  '
  SELECT mi.id AS menu_item_id,
         mi.item_name AS item_name,
         SUM(oi.qty * mi.price) AS revenue
  FROM order_items oi
  JOIN orders o ON o.id = oi.order_id
  JOIN menu_items mi ON mi.id = oi.menu_item_id
  WHERE o.status = ''delivered''
  GROUP BY mi.id, mi.item_name
  ORDER BY revenue DESC, menu_item_id ASC
  LIMIT 5;
  ',
  'ordered'
);

-- HARD 2: рестораны, у которых средняя сумма заказа выше средней по всем ресторанам
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Delivery: Рестораны со средним чеком выше среднего',
  'Сравнить средний чек ресторана со средним по всем ресторанам.',
  'Hard',
  'Считайте только delivered заказы.
Посчитайте сумму заказа как SUM(qty*price) + delivery_fee.
Найдите рестораны, у которых средний чек выше среднего по всем ресторанам.

Ожидаемые колонки: restaurant_id, avg_order_total',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE customers (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE restaurants (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE menu_items (id INTEGER PRIMARY KEY, restaurant_id INTEGER NOT NULL, item_name TEXT NOT NULL, price INTEGER NOT NULL, category TEXT NOT NULL,
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL, restaurant_id INTEGER NOT NULL, ordered_at TEXT NOT NULL, status TEXT NOT NULL, delivery_fee INTEGER NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id), FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE order_items (id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, menu_item_id INTEGER NOT NULL, qty INTEGER NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(menu_item_id) REFERENCES menu_items(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 15)
  INSERT INTO customers(id, full_name, city)
  SELECT n, ''Customer '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO restaurants(id, name, city)
  SELECT n, ''Restaurant '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 30)
  INSERT INTO menu_items(id, restaurant_id, item_name, price, category)
  SELECT n, 1 + (n % 10), ''Item '' || n,
    5 + (n % 16) * 2,
    CASE (n % 5) WHEN 0 THEN ''Pizza'' WHEN 1 THEN ''Burger'' WHEN 2 THEN ''Salad'' WHEN 3 THEN ''Sushi'' ELSE ''Dessert'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, customer_id, restaurant_id, ordered_at, status, delivery_fee)
  SELECT n, 1 + (n % 15), 1 + (n % 10),
    datetime(''2026-01-01 12:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 14) || '' days''),
    CASE WHEN (n % 7) = 0 THEN ''cancelled'' ELSE ''delivered'' END,
    2 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 80)
  INSERT INTO order_items(id, order_id, menu_item_id, qty)
  SELECT n, 1 + (n % 50), 1 + (n % 30), 1 + (n % 3)
  FROM seq;
  ',
  '
  WITH order_totals AS (
    SELECT o.id AS order_id,
           o.restaurant_id AS restaurant_id,
           (SUM(oi.qty * mi.price) + o.delivery_fee) AS total_amount
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN menu_items mi ON mi.id = oi.menu_item_id
    WHERE o.status = ''delivered''
    GROUP BY o.id, o.restaurant_id, o.delivery_fee
  ),
  per_rest AS (
    SELECT restaurant_id,
           AVG(total_amount) AS avg_order_total
    FROM order_totals
    GROUP BY restaurant_id
  )
  SELECT restaurant_id, avg_order_total
  FROM per_rest
  WHERE avg_order_total > (SELECT AVG(avg_order_total) FROM per_rest)
  ORDER BY avg_order_total DESC, restaurant_id ASC;
  ',
  'ordered'
);

-- ADVANCED 1: топ-категория по выручке (delivered)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Delivery: Лучшая категория по выручке',
  'Найти категорию блюд с максимальной выручкой (delivered).',
  'Advanced',
  'Посчитайте выручку по категориям блюд (menu_items.category) по delivered заказам.
Выручка категории = SUM(qty * price).
Выведите категорию с максимальной выручкой.

Ожидаемые колонки: category, revenue',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE customers (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE restaurants (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE menu_items (id INTEGER PRIMARY KEY, restaurant_id INTEGER NOT NULL, item_name TEXT NOT NULL, price INTEGER NOT NULL, category TEXT NOT NULL,
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL, restaurant_id INTEGER NOT NULL, ordered_at TEXT NOT NULL, status TEXT NOT NULL, delivery_fee INTEGER NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id), FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE order_items (id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, menu_item_id INTEGER NOT NULL, qty INTEGER NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(menu_item_id) REFERENCES menu_items(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 15)
  INSERT INTO customers(id, full_name, city)
  SELECT n, ''Customer '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO restaurants(id, name, city)
  SELECT n, ''Restaurant '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 30)
  INSERT INTO menu_items(id, restaurant_id, item_name, price, category)
  SELECT n, 1 + (n % 10), ''Item '' || n,
    5 + (n % 16) * 2,
    CASE (n % 5) WHEN 0 THEN ''Pizza'' WHEN 1 THEN ''Burger'' WHEN 2 THEN ''Salad'' WHEN 3 THEN ''Sushi'' ELSE ''Dessert'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, customer_id, restaurant_id, ordered_at, status, delivery_fee)
  SELECT n, 1 + (n % 15), 1 + (n % 10),
    datetime(''2026-01-01 12:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 14) || '' days''),
    CASE WHEN (n % 7) = 0 THEN ''cancelled'' ELSE ''delivered'' END,
    2 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 80)
  INSERT INTO order_items(id, order_id, menu_item_id, qty)
  SELECT n, 1 + (n % 50), 1 + (n % 30), 1 + (n % 3)
  FROM seq;
  ',
  '
  SELECT mi.category AS category,
         SUM(oi.qty * mi.price) AS revenue
  FROM order_items oi
  JOIN orders o ON o.id = oi.order_id
  JOIN menu_items mi ON mi.id = oi.menu_item_id
  WHERE o.status = ''delivered''
  GROUP BY mi.category
  ORDER BY revenue DESC, category ASC
  LIMIT 1;
  ',
  'ordered'
);

-- ADVANCED 2: по каждому ресторану самое популярное блюдо по количеству (delivered)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Delivery: Самое популярное блюдо в ресторане',
  'Для каждого ресторана найти блюдо с максимальным суммарным qty.',
  'Advanced',
  'Для каждого ресторана найдите блюдо, которое заказали в сумме больше всего (SUM(qty)) по delivered заказам.
Если несколько — выберите блюдо с меньшим menu_item_id.

Ожидаемые колонки: restaurant_id, menu_item_id, qty_total',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE customers (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE restaurants (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE menu_items (id INTEGER PRIMARY KEY, restaurant_id INTEGER NOT NULL, item_name TEXT NOT NULL, price INTEGER NOT NULL, category TEXT NOT NULL,
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL, restaurant_id INTEGER NOT NULL, ordered_at TEXT NOT NULL, status TEXT NOT NULL, delivery_fee INTEGER NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id), FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE order_items (id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, menu_item_id INTEGER NOT NULL, qty INTEGER NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(menu_item_id) REFERENCES menu_items(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 15)
  INSERT INTO customers(id, full_name, city)
  SELECT n, ''Customer '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO restaurants(id, name, city)
  SELECT n, ''Restaurant '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 30)
  INSERT INTO menu_items(id, restaurant_id, item_name, price, category)
  SELECT n, 1 + (n % 10), ''Item '' || n,
    5 + (n % 16) * 2,
    CASE (n % 5) WHEN 0 THEN ''Pizza'' WHEN 1 THEN ''Burger'' WHEN 2 THEN ''Salad'' WHEN 3 THEN ''Sushi'' ELSE ''Dessert'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, customer_id, restaurant_id, ordered_at, status, delivery_fee)
  SELECT n, 1 + (n % 15), 1 + (n % 10),
    datetime(''2026-01-01 12:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 14) || '' days''),
    CASE WHEN (n % 7) = 0 THEN ''cancelled'' ELSE ''delivered'' END,
    2 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 80)
  INSERT INTO order_items(id, order_id, menu_item_id, qty)
  SELECT n, 1 + (n % 50), 1 + (n % 30), 1 + (n % 3)
  FROM seq;
  ',
  '
  WITH per_item AS (
    SELECT o.restaurant_id AS restaurant_id,
           oi.menu_item_id AS menu_item_id,
           SUM(oi.qty) AS qty_total
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    WHERE o.status = ''delivered''
    GROUP BY o.restaurant_id, oi.menu_item_id
  ),
  ranked AS (
    SELECT restaurant_id, menu_item_id, qty_total,
           ROW_NUMBER() OVER (PARTITION BY restaurant_id ORDER BY qty_total DESC, menu_item_id ASC) AS rn
    FROM per_item
  )
  SELECT restaurant_id, menu_item_id, qty_total
  FROM ranked
  WHERE rn = 1
  ORDER BY restaurant_id;
  ',
  'ordered'
);

-- ADVANCED 3: медиана суммы заказа (items + delivery_fee) по delivered
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Delivery: Медиана суммы заказа',
  'Посчитать медиану суммы заказа (delivered).',
  'Advanced',
  'Считайте только delivered заказы.
Сумма заказа = SUM(qty*price) + delivery_fee.
Посчитайте медиану этих сумм.

Ожидаемая колонка: median_total',
  '
  PRAGMA foreign_keys = ON;
  CREATE TABLE customers (id INTEGER PRIMARY KEY, full_name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE restaurants (id INTEGER PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL);
  CREATE TABLE menu_items (id INTEGER PRIMARY KEY, restaurant_id INTEGER NOT NULL, item_name TEXT NOT NULL, price INTEGER NOT NULL, category TEXT NOT NULL,
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL, restaurant_id INTEGER NOT NULL, ordered_at TEXT NOT NULL, status TEXT NOT NULL, delivery_fee INTEGER NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id), FOREIGN KEY(restaurant_id) REFERENCES restaurants(id));
  CREATE TABLE order_items (id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, menu_item_id INTEGER NOT NULL, qty INTEGER NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id), FOREIGN KEY(menu_item_id) REFERENCES menu_items(id));
  ',
  '
  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 15)
  INSERT INTO customers(id, full_name, city)
  SELECT n, ''Customer '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10)
  INSERT INTO restaurants(id, name, city)
  SELECT n, ''Restaurant '' || n,
    CASE (n % 4) WHEN 0 THEN ''Amsterdam'' WHEN 1 THEN ''Utrecht'' WHEN 2 THEN ''Rotterdam'' ELSE ''Eindhoven'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 30)
  INSERT INTO menu_items(id, restaurant_id, item_name, price, category)
  SELECT n, 1 + (n % 10), ''Item '' || n,
    5 + (n % 16) * 2,
    CASE (n % 5) WHEN 0 THEN ''Pizza'' WHEN 1 THEN ''Burger'' WHEN 2 THEN ''Salad'' WHEN 3 THEN ''Sushi'' ELSE ''Dessert'' END
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50)
  INSERT INTO orders(id, customer_id, restaurant_id, ordered_at, status, delivery_fee)
  SELECT n, 1 + (n % 15), 1 + (n % 10),
    datetime(''2026-01-01 12:00:00'', ''+'' || (n % 20) || '' hours'', ''+'' || (n % 14) || '' days''),
    CASE WHEN (n % 7) = 0 THEN ''cancelled'' ELSE ''delivered'' END,
    2 + (n % 5)
  FROM seq;

  WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 80)
  INSERT INTO order_items(id, order_id, menu_item_id, qty)
  SELECT n, 1 + (n % 50), 1 + (n % 30), 1 + (n % 3)
  FROM seq;
  ',
  '
  WITH order_totals AS (
    SELECT o.id AS order_id,
           (SUM(oi.qty * mi.price) + o.delivery_fee) AS total_amount
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN menu_items mi ON mi.id = oi.menu_item_id
    WHERE o.status = ''delivered''
    GROUP BY o.id, o.delivery_fee
  )
  SELECT AVG(total_amount) AS median_total
  FROM (
    SELECT total_amount
    FROM order_totals
    ORDER BY total_amount
    LIMIT 2 - (SELECT COUNT(*) FROM order_totals) % 2
    OFFSET (SELECT (COUNT(*) - 1) / 2 FROM order_totals)
  );
  ',
  'unordered'
);
