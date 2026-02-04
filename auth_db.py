import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Dict

from werkzeug.security import generate_password_hash, check_password_hash

AUTH_DB = Path("data/auth.db")


@dataclass(frozen=True)
class User:
    id: int
    login: str
    email: str
    password_hash: str

    def verify_password(self, password: str) -> bool:
        return check_password_hash(self.password_hash, password)


@dataclass(frozen=True)
class TaskProgress:
    user_id: int
    task_id: int
    attempts: int
    solved: bool
    solved_at: Optional[str]
    last_attempt_at: Optional[str]
    best_sql: Optional[str]
    last_sql: Optional[str]


def connect_auth_db() -> sqlite3.Connection:
    AUTH_DB.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(AUTH_DB)
    conn.row_factory = sqlite3.Row
    return conn


def init_auth_db() -> None:
    """Create auth DB/tables if missing (safe to call on startup)."""
    AUTH_DB.parent.mkdir(parents=True, exist_ok=True)
    with connect_auth_db() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                login TEXT NOT NULL UNIQUE,
                email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                last_login_at TEXT
            );
            """
        )
        conn.execute("CREATE INDEX IF NOT EXISTS idx_users_login ON users(login);")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);")

        # Per-user progress
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS user_task_progress (
                user_id INTEGER NOT NULL,
                task_id INTEGER NOT NULL,
                attempts INTEGER NOT NULL DEFAULT 0,
                solved INTEGER NOT NULL DEFAULT 0,
                solved_at TEXT,
                last_attempt_at TEXT,
                best_sql TEXT,
                last_sql TEXT,
                PRIMARY KEY (user_id, task_id),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
            """
        )
        
        # Lightweight migration: add columns if auth.db already existed from previous versions
        cols = {r["name"] for r in conn.execute("PRAGMA table_info(user_task_progress)").fetchall()}
        if "last_sql" not in cols:
            conn.execute("ALTER TABLE user_task_progress ADD COLUMN last_sql TEXT;")
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_progress_user ON user_task_progress(user_id);"
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_progress_task ON user_task_progress(task_id);"
        )

        # Attempts history (optional but useful for analytics/debug)
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS user_task_attempts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                task_id INTEGER NOT NULL,
                sql TEXT NOT NULL,
                is_correct INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
            """
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_attempts_user_task ON user_task_attempts(user_id, task_id);"
        )
        conn.commit()


def get_user_by_id(user_id: int) -> Optional[User]:
    with connect_auth_db() as conn:
        row = conn.execute(
            "SELECT id, login, email, password_hash FROM users WHERE id = ?",
            (int(user_id),),
        ).fetchone()
        if not row:
            return None
        return User(int(row["id"]), row["login"], row["email"], row["password_hash"])


def get_user_by_login(login: str) -> Optional[User]:
    with connect_auth_db() as conn:
        row = conn.execute(
            "SELECT id, login, email, password_hash FROM users WHERE login = ?",
            (login,),
        ).fetchone()
        if not row:
            return None
        return User(int(row["id"]), row["login"], row["email"], row["password_hash"])


def get_user_by_email(email: str) -> Optional[User]:
    with connect_auth_db() as conn:
        row = conn.execute(
            "SELECT id, login, email, password_hash FROM users WHERE email = ?",
            (email,),
        ).fetchone()
        if not row:
            return None
        return User(int(row["id"]), row["login"], row["email"], row["password_hash"])


def create_user(login: str, email: str, password: str) -> User:
    password_hash = generate_password_hash(password)
    with connect_auth_db() as conn:
        cur = conn.execute(
            "INSERT INTO users (login, email, password_hash) VALUES (?, ?, ?)",
            (login, email, password_hash),
        )
        conn.commit()
        user_id = int(cur.lastrowid)
    return User(user_id, login, email, password_hash)


def touch_last_login(user_id: int) -> None:
    with connect_auth_db() as conn:
        conn.execute(
            "UPDATE users SET last_login_at = datetime('now') WHERE id = ?",
            (int(user_id),),
        )
        conn.commit()


def get_progress_map(user_id: int) -> Dict[int, TaskProgress]:
    """Return mapping task_id -> progress for a user."""
    with connect_auth_db() as conn:
        rows = conn.execute(
            """
            SELECT user_id, task_id, attempts, solved, solved_at, last_attempt_at, best_sql, last_sql
            FROM user_task_progress
            WHERE user_id = ?
            """,
            (int(user_id),),
        ).fetchall()

    out: Dict[int, TaskProgress] = {}
    for r in rows:
        out[int(r["task_id"])] = TaskProgress(
            user_id=int(r["user_id"]),
            task_id=int(r["task_id"]),
            attempts=int(r["attempts"]),
            solved=bool(r["solved"]),
            solved_at=r["solved_at"],
            last_attempt_at=r["last_attempt_at"],
            best_sql=r["best_sql"],
            last_sql=r["last_sql"],
        )
    return out

def get_progress_counts(user_id: int) -> tuple[int, int]:
    """Return (solved_count, attempted_count) for a user."""
    with connect_auth_db() as conn:
        r = conn.execute(
            """
            SELECT
              SUM(CASE WHEN solved = 1 THEN 1 ELSE 0 END) AS solved_count,
              COUNT(*) AS attempted_count
            FROM user_task_progress
            WHERE user_id = ?
            """,
            (int(user_id),),
        ).fetchone()
    solved = int(r["solved_count"] or 0)
    attempted = int(r["attempted_count"] or 0)
    return solved, attempted



def get_task_progress(user_id: int, task_id: int) -> Optional[TaskProgress]:
    with connect_auth_db() as conn:
        r = conn.execute(
            """
            SELECT user_id, task_id, attempts, solved, solved_at, last_attempt_at, best_sql, last_sql
            FROM user_task_progress
            WHERE user_id = ? AND task_id = ?
            """,
            (int(user_id), int(task_id)),
        ).fetchone()
        if not r:
            return None
        return TaskProgress(
            user_id=int(r["user_id"]),
            task_id=int(r["task_id"]),
            attempts=int(r["attempts"]),
            solved=bool(r["solved"]),
            solved_at=r["solved_at"],
            last_attempt_at=r["last_attempt_at"],
            best_sql=r["best_sql"],
            last_sql=r["last_sql"],
        )


def record_attempt(user_id: int, task_id: int, sql: str, is_correct: bool) -> None:
    """
    Record an attempt and update aggregate progress.

    Rules:
    - attempts++ always
    - last_attempt_at updated always
    - on first correct attempt: solved=1, solved_at set, best_sql stored
      (if already solved, we keep existing best_sql by default)
    """
    uid = int(user_id)
    tid = int(task_id)
    sql_text = (sql or "").strip()
    correct_int = 1 if is_correct else 0

    with connect_auth_db() as conn:
        conn.execute(
            "INSERT INTO user_task_attempts (user_id, task_id, sql, is_correct) VALUES (?, ?, ?, ?)",
            (uid, tid, sql_text, correct_int),
        )

        # Upsert aggregate progress
        conn.execute(
            """
            INSERT INTO user_task_progress (user_id, task_id, attempts, solved, last_attempt_at, last_sql)
            VALUES (?, ?, 1, ?, datetime('now'), ?)
            ON CONFLICT(user_id, task_id)
            DO UPDATE SET
                attempts = attempts + 1,
                last_attempt_at = datetime('now'),
                last_sql = excluded.last_sql
            """,
            (uid, tid, correct_int, sql_text),
        )

        if is_correct:
            # Mark solved only if not solved yet
            conn.execute(
                """
                UPDATE user_task_progress
                SET solved = 1,
                    solved_at = COALESCE(solved_at, datetime('now')),
                    best_sql = COALESCE(best_sql, ?)
                WHERE user_id = ? AND task_id = ?
                """,
                (sql_text, uid, tid),
            )

        conn.commit()
