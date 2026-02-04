import sqlite3
import threading
import time
from collections import Counter, OrderedDict
from pathlib import Path
from typing import Iterable, Optional, Tuple, List, Any

APP_DB = Path("data/app.db")
DATASETS_DIR = Path("data/datasets")

# Fixed difficulty order for UI (если используешь в будущем)
LEVELS_ORDER = ["Easy", "Medium", "Hard", "Advanced"]

# Один lock на процесс: защищает от одновременного создания dataset-файлов в разных потоках Flask
_DATASET_CREATE_LOCK = threading.Lock()


# -----------------------------
# App DB (каталог задач)
# -----------------------------
def connect_app_db() -> sqlite3.Connection:
    """Connection to catalog DB (tasks list)."""
    conn = sqlite3.connect(APP_DB)
    conn.row_factory = sqlite3.Row
    return conn


def init_app_db(schema_path: Path = Path("schema.sql")) -> None:
    """
    Create and seed app.db if it doesn't exist yet.
    For a local pet project: run schema.sql once when app.db is missing.
    """
    if APP_DB.exists():
        return

    APP_DB.parent.mkdir(parents=True, exist_ok=True)
    sql = schema_path.read_text(encoding="utf-8")

    conn = sqlite3.connect(APP_DB)
    try:
        conn.executescript(sql)
        conn.commit()
    finally:
        conn.close()


def get_tasks(level: str | None = None):
    """Get tasks list. If level is provided, filter by level."""
    sql = "SELECT id, title, short_desc, level FROM tasks"
    params: list[Any] = []

    if level and level in LEVELS_ORDER:
        sql += " WHERE level = ?"
        params.append(level)

    sql += " ORDER BY id"

    with connect_app_db() as conn:
        return conn.execute(sql, params).fetchall()


def get_tasks_count() -> int:
    """Total number of tasks in app DB."""
    with connect_app_db() as conn:
        r = conn.execute("SELECT COUNT(*) AS cnt FROM tasks").fetchone()
        return int(r["cnt"])



def get_task(task_id: int):
    with connect_app_db() as conn:
        return conn.execute("SELECT * FROM tasks WHERE id = ?", (task_id,)).fetchone()


# -----------------------------
# Dataset DB helpers
# -----------------------------
def dataset_path(task_id: int) -> Path:
    DATASETS_DIR.mkdir(parents=True, exist_ok=True)
    return DATASETS_DIR / f"task_{int(task_id)}.db"


def ensure_dataset(task_row) -> None:
    """
    Create dataset DB for a task if missing.

    Fixes:
    - lock (защита от одновременного создания одной и той же БД)
    - создание в temp-файл и атомарный replace -> никогда не будет "полусозданной" БД
    """
    task_id = int(task_row["id"])
    final_path = dataset_path(task_id)

    if final_path.exists():
        return

    with _DATASET_CREATE_LOCK:
        if final_path.exists():
            return

        tmp_path = final_path.with_suffix(".db.tmp")
        if tmp_path.exists():
            tmp_path.unlink()

        conn = sqlite3.connect(tmp_path)
        try:
            conn.row_factory = sqlite3.Row
            conn.execute("PRAGMA busy_timeout = 5000;")
            conn.execute("PRAGMA foreign_keys = ON;")

            dataset_sql = (task_row["dataset_sql"] or "").strip()
            seed_sql = (task_row["seed_sql"] or "").strip()

            # Один executescript, транзакция внутри него.
            # Ведущий ";\n" — страховка, если где-то забыли ';' перед WITH/INSERT.
            script = (
                "BEGIN IMMEDIATE;\n"
                ";\n" + dataset_sql + "\n"
                ";\n" + seed_sql + "\n"
                ";\nCOMMIT;\n"
            )

            conn.executescript(script)

        except Exception:
            try:
                conn.rollback()
            except Exception:
                pass
            raise
        finally:
            conn.close()

        tmp_path.replace(final_path)


# -----------------------------
# SQL validation (UX слой)
# -----------------------------
def _strip_leading_comments(sql: str) -> str:
    s = sql.lstrip()
    while True:
        if s.startswith("--"):
            nl = s.find("\n")
            s = "" if nl == -1 else s[nl + 1 :].lstrip()
            continue
        if s.startswith("/*"):
            end = s.find("*/")
            if end == -1:
                return s
            s = s[end + 2 :].lstrip()
            continue
        break
    return s


def _tokenize_sql(sql: str) -> list[str]:
    """
    Very small tokenizer for validation (not a full SQL parser).
    - skips comments
    - skips string literals ('...' and "...")
    - returns identifier/keyword-like tokens (letters, digits, underscore)
    """
    tokens: list[str] = []
    s = sql
    i = 0
    n = len(s)

    while i < n:
        ch = s[i]

        if ch.isspace():
            i += 1
            continue

        # line comment --
        if ch == "-" and i + 1 < n and s[i + 1] == "-":
            j = s.find("\n", i + 2)
            i = n if j == -1 else j + 1
            continue

        # block comment /* ... */
        if ch == "/" and i + 1 < n and s[i + 1] == "*":
            j = s.find("*/", i + 2)
            i = n if j == -1 else j + 2
            continue

        # string literals '...' or "..." (double quotes can be identifiers in SQL,
        # но для упрощения считаем их строками и не токенизируем содержимое)
        if ch in ("'", '"'):
            quote = ch
            i += 1
            while i < n:
                if s[i] == quote:
                    # escaped quote inside string: '' or ""
                    if i + 1 < n and s[i + 1] == quote:
                        i += 2
                        continue
                    i += 1
                    break
                i += 1
            continue

        if ch.isalpha() or ch == "_":
            j = i + 1
            while j < n and (s[j].isalnum() or s[j] == "_"):
                j += 1
            tokens.append(s[i:j].lower())
            i = j
            continue

        i += 1

    return tokens


def validate_select_only(sql: str) -> None:
    """
    UX-валидация: "только SELECT".
    Реальная защита идёт уровнем ниже: read-only + query_only + authorizer.

    Allow:
      - SELECT ...
      - WITH ... SELECT ...

    Disallow keywords anywhere (вне строк/комментов):
      INSERT/UPDATE/DELETE/REPLACE/CREATE/DROP/ALTER/PRAGMA/VACUUM/ATTACH/DETACH/TRANSACTION/BEGIN/COMMIT/ROLLBACK
    """
    s = _strip_leading_comments(sql.strip())
    tokens = _tokenize_sql(s)
    if not tokens:
        raise ValueError("Введите SQL-запрос.")

    first = tokens[0]
    if first not in ("select", "with"):
        raise ValueError("Разрешены только SELECT-запросы (запрещены изменения данных и структуры).")

    forbidden = {
        "insert",
        "update",
        "delete",
        "replace",
        "create",
        "drop",
        "alter",
        "pragma",
        "vacuum",
        "attach",
        "detach",
        "transaction",
        "begin",
        "commit",
        "rollback",
    }

    for t in tokens:
        if t in forbidden:
            raise ValueError("Разрешены только SELECT-запросы (запрещены изменения данных и структуры).")

    # если WITH — должен содержать SELECT
    if first == "with" and "select" not in tokens:
        raise ValueError("Разрешены только SELECT-запросы (WITH должен заканчиваться SELECT).")


# -----------------------------
# SQLite sandbox (реальная защита)
# -----------------------------
def _connect_readonly_sqlite(db_path: Path) -> sqlite3.Connection:
    """
    Open SQLite DB in read-only mode:
    - URI mode=ro forbids writes at file level
    - PRAGMA query_only forbids writes at engine level
    """
    conn = sqlite3.connect(f"file:{db_path.as_posix()}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA query_only = ON;")
    return conn


def _add_query_timeout(conn: sqlite3.Connection, max_ms: int = 200) -> None:
    """
    Prevent heavy / infinite queries (DoS) using progress handler.
    """
    deadline = time.monotonic() + (max_ms / 1000)

    def handler() -> int:
        return 1 if time.monotonic() > deadline else 0

    # called every N virtual machine instructions
    conn.set_progress_handler(handler, 10_000)


def _install_readonly_authorizer(conn: sqlite3.Connection) -> None:
    """
    Additional sandbox: deny any non-read actions (DDL/DML/pragma/attach/transactions).
    Works even if UX-validator misses something.
    """
    SQLITE_DENY = sqlite3.SQLITE_DENY
    SQLITE_OK = sqlite3.SQLITE_OK

    forbidden_actions = {
        getattr(sqlite3, "SQLITE_INSERT", None),
        getattr(sqlite3, "SQLITE_UPDATE", None),
        getattr(sqlite3, "SQLITE_DELETE", None),
        getattr(sqlite3, "SQLITE_CREATE_TABLE", None),
        getattr(sqlite3, "SQLITE_CREATE_INDEX", None),
        getattr(sqlite3, "SQLITE_CREATE_VIEW", None),
        getattr(sqlite3, "SQLITE_DROP_TABLE", None),
        getattr(sqlite3, "SQLITE_DROP_INDEX", None),
        getattr(sqlite3, "SQLITE_DROP_VIEW", None),
        getattr(sqlite3, "SQLITE_ALTER_TABLE", None),
        getattr(sqlite3, "SQLITE_PRAGMA", None),
        getattr(sqlite3, "SQLITE_ATTACH", None),
        getattr(sqlite3, "SQLITE_DETACH", None),
        getattr(sqlite3, "SQLITE_TRANSACTION", None),
    }
    forbidden_actions.discard(None)

    def authorizer(action, arg1, arg2, dbname, source):
        if action in forbidden_actions:
            return SQLITE_DENY
        return SQLITE_OK

    conn.set_authorizer(authorizer)


# -----------------------------
# User SQL execution
# -----------------------------
def run_user_sql(task_id: int, sql: str, limit: int = 500, timeout_ms: int = 200):
    """
    Execute SQL against dataset DB of given task (READ-ONLY sandbox).
    Returns (columns, rows) for SELECT-like queries, otherwise (None, None).
    """
    path = dataset_path(task_id)

    cleaned = (sql or "").strip()
    validate_select_only(cleaned)

    # single statement only
    if ";" in cleaned.rstrip(";"):
        raise ValueError("Пожалуйста, выполните один SQL-запрос без нескольких команд через ';'.")

    conn = _connect_readonly_sqlite(path)
    _install_readonly_authorizer(conn)
    _add_query_timeout(conn, max_ms=timeout_ms)

    try:
        cur = conn.cursor()
        cur.execute(cleaned)

        if cur.description is None:
            return None, None

        cols = [d[0] for d in cur.description]
        rows = cur.fetchmany(limit)
        return cols, rows

    except sqlite3.OperationalError as e:
        # progress_handler обычно приводит к "interrupted"
        if "interrupted" in str(e).lower():
            raise ValueError("Запрос выполнялся слишком долго и был прерван. Упростите запрос.") from e
        raise
    finally:
        conn.close()


# -----------------------------
# Results comparison
# -----------------------------
def compare_results(user_cols, user_rows, sol_cols, sol_rows, mode: str):
    """
    Compare user's result to solution result.
    - Column names must match (case-insensitive).
    - Data compare:
        ordered   -> exact row order matters
        unordered -> order doesn't matter (multiset compare, duplicates are counted)
    Returns: (is_ok: bool, message: str)
    """
    if user_cols is None or sol_cols is None:
        return False, "Запрос должен возвращать табличный результат (SELECT/WITH)."

    if [c.lower() for c in user_cols] != [c.lower() for c in sol_cols]:
        return False, f"Колонки отличаются. Ожидалось: {sol_cols}"

    user_tuples = [tuple(r[c] for c in user_cols) for r in user_rows]
    sol_tuples = [tuple(r[c] for c in sol_cols) for r in sol_rows]

    mode = (mode or "unordered").lower()
    if mode == "ordered":
        ok = user_tuples == sol_tuples
        return ok, ("Совпадает." if ok else "Значения/порядок строк не совпадают с ожидаемыми.")
    else:
        ok = Counter(user_tuples) == Counter(sol_tuples)
        return ok, ("Совпадает (порядок строк не важен)." if ok else "Значения не совпадают с ожидаемыми.")


# -----------------------------
# Sample data for UI
# -----------------------------
def _quote_ident(name: str) -> str:
    # Double-quote escaping for SQLite identifiers
    return '"' + (name or "").replace('"', '""') + '"'


def get_sample_data(task_id: int, limit: int = 5):
    """
    Returns OrderedDict[table_name] = {"columns": [...], "rows": [...]}
    Used to show small previews of dataset tables in UI.
    """
    path = dataset_path(task_id)
    conn = _connect_readonly_sqlite(path)
    _install_readonly_authorizer(conn)
    _add_query_timeout(conn, max_ms=200)

    try:
        cur = conn.cursor()

        cur.execute(
            """
            SELECT name
            FROM sqlite_master
            WHERE type='table'
              AND name NOT LIKE 'sqlite_%'
            ORDER BY name
            """
        )
        tables = [r["name"] for r in cur.fetchall()]

        result = OrderedDict()

        for table in tables:
            try:
                cur.execute(f"SELECT * FROM {_quote_ident(table)} LIMIT ?", (limit,))
                rows = cur.fetchall()
                columns = [d[0] for d in cur.description] if cur.description else []
                result[table] = {"columns": columns, "rows": rows}
            except sqlite3.Error:
                continue

        return result
    finally:
        conn.close()
