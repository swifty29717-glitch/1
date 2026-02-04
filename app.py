from flask import Flask, render_template, request
from flask_login import LoginManager, current_user, login_required

import db
import auth_db
from auth import auth_bp, SessionUser

app = Flask(__name__)
app.secret_key = "dev-secret-key"

# Init DBs at startup (Flask 3.x removed before_first_request)
db.init_app_db()
auth_db.init_auth_db()

# Flask-Login setup
login_manager = LoginManager()
login_manager.login_view = "auth.login"
login_manager.init_app(app)

# ===== Difficulty levels (canonical) =====
LEVELS = ["Easy", "Medium", "Hard", "Advanced"]


@login_manager.user_loader
def load_user(user_id: str):
    try:
        uid = int(user_id)
    except (TypeError, ValueError):
        return None
    user = auth_db.get_user_by_id(uid)
    return SessionUser(user) if user else None


@app.context_processor
def inject_globals():
    # Expose LEVELS and (if logged in) progress summary to all templates
    ctx = {"LEVELS": LEVELS}

    if current_user.is_authenticated:
        total_tasks = db.get_tasks_count()
        solved, attempted = auth_db.get_progress_counts(current_user.id)
        percent = int(round((solved / total_tasks) * 100)) if total_tasks else 0
        ctx.update(
            {
                "progress_total": total_tasks,
                "progress_solved": solved,
                "progress_attempted": attempted,
                "progress_percent": percent,
            }
        )

    return ctx


# Register auth blueprint
app.register_blueprint(auth_bp)

# ===== Lectures catalog (static pages) =====
LECTURES = [
    {
        "slug": "sql_basics",
        "title": "SQL basics",
        "summary": "SELECT, FROM, базовые типы данных и простые условия.",
        "level": "Easy",
        "icon": "📘",
    },
    {
        "slug": "where",
        "title": "WHERE — фильтрация строк",
        "summary": "Условия, операторы сравнения, BETWEEN/IN/LIKE, NULL.",
        "level": "Easy",
        "icon": "🔎",
    },
    {
        "slug": "group-by",
        "title": "GROUP BY — агрегаты",
        "summary": "COUNT/SUM/AVG, группировки, HAVING, частые ошибки.",
        "level": "Medium",
        "icon": "🧮",
    },
    {
        "slug": "joins",
        "title": "JOIN",
        "summary": "INNER/LEFT JOIN, ключи, типичные ловушки и дубликаты.",
        "level": "Medium",
        "icon": "🔗",
    },
    {
        "slug": "window_functions",
        "title": "Оконные функции в SQL",
        "summary": "OVER(PARTITION BY ...), ROW_NUMBER, ранжирование и аналитика.",
        "level": "Hard",
        "icon": "🪟",
    },
]


@app.route("/", methods=["GET", "POST"])
def index():
    # Some apps (e.g. Steam) may POST to localhost:5000. We ignore it.
    if request.method == "POST":
        return ("", 204)

    selected_level = request.args.get("level")  # Easy/Medium/Hard/Advanced or empty
    tasks = db.get_tasks(level=selected_level)

    # ===== Landing helpers (do not change catalog, only enrich homepage) =====
    # 1) Recommended start: first 3 Easy tasks (by id)
    easy_tasks = db.get_tasks(level="Easy")
    recommended = list(easy_tasks[:3])
    start_task_id = int(recommended[0]["id"]) if recommended else (int(tasks[0]["id"]) if tasks else 1)

    progress_map = None
    if current_user.is_authenticated:
        progress_map = auth_db.get_progress_map(current_user.id)

    return render_template(
        "index.html",
        tasks=tasks,
        selected_level=selected_level,
        progress_map=progress_map,
        recommended=recommended,
        start_task_id=start_task_id,
        # levels param can remain for backward-compat with template,
        # but template should prefer LEVELS from context_processor
        levels=LEVELS,
    )


@app.route("/task/<int:task_id>", methods=["GET", "POST"])
def task_page(task_id: int):
    task = db.get_task(task_id)
    if task is None:
        return "Task not found", 404

    # Ensure dataset exists for this task
    db.ensure_dataset(task)

    # Show real sample data from the dataset
    sample_data = db.get_sample_data(task_id, limit=5)

    sql = ""
    columns = None
    rows = None
    error = None

    verdict = None
    verdict_msg = None

    progress = None
    if current_user.is_authenticated:
        progress = auth_db.get_task_progress(current_user.id, task_id)
        if progress and progress.last_sql and request.method == "GET":
            sql = progress.last_sql

    if request.method == "POST":
        sql = request.form.get("sql", "").strip()

        if not sql:
            error = "Введите SQL-запрос."
        else:
            try:
                columns, rows = db.run_user_sql(task_id, sql)

                sol_cols, sol_rows = db.run_user_sql(task_id, task["solution_sql"])
                verdict, verdict_msg = db.compare_results(
                    columns,
                    rows,
                    sol_cols,
                    sol_rows,
                    task["check_mode"],
                )

                if current_user.is_authenticated:
                    auth_db.record_attempt(current_user.id, task_id, sql, bool(verdict))
                    progress = auth_db.get_task_progress(current_user.id, task_id)
            except Exception as e:
                error = str(e)

    return render_template(
        "task.html",
        task=task,
        sql=sql,
        columns=columns,
        rows=rows,
        error=error,
        verdict=verdict,
        verdict_msg=verdict_msg,
        sample_data=sample_data,
        progress=progress,
    )


@app.route("/profile")
@login_required
def profile():
    tasks = db.get_tasks(level=None)
    progress_map = auth_db.get_progress_map(current_user.id)

    solved = sum(1 for p in progress_map.values() if p.solved)
    attempted = len(progress_map)
    total = len(tasks)
    percent = int(round((solved / total) * 100)) if total else 0

    return render_template(
        "profile.html",
        tasks=tasks,
        progress_map=progress_map,
        solved=solved,
        attempted=attempted,
        total=total,
        percent=percent,
    )


@app.route("/lectures")
def lectures_index():
    selected_level = request.args.get("level")  # Easy/Medium/Hard/Advanced or empty

    lectures = LECTURES
    if selected_level:
        lectures = [l for l in LECTURES if l["level"] == selected_level]

    return render_template(
        "lectures/index.html",
        lectures=lectures,
        selected_level=selected_level,
        levels=LEVELS,
    )


@app.route("/lectures/<slug>")
def lecture_page(slug: str):
    allowed = {
        "where": "lectures/where.html",
        "group-by": "lectures/group_by.html",
        "joins": "lectures/joins.html",
        "window_functions": "lectures/window_functions.html",
        "sql_basics": "lectures/sql_basics.html",
    }
    template = allowed.get(slug)
    if not template:
        return "Lecture not found", 404
    return render_template(template)


@app.route("/about")
def about():
    return render_template("about.html")


if __name__ == "__main__":
    app.run(debug=True)