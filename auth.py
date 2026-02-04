import re

from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_user, logout_user, login_required, UserMixin

import auth_db


auth_bp = Blueprint("auth", __name__)


_LOGIN_RE = re.compile(r"^[a-zA-Z0-9_.]{3,32}$")


class SessionUser(UserMixin):
    """Flask-Login adapter around auth_db.User (we keep db-layer pure)."""

    def __init__(self, user: auth_db.User):
        self.id = user.id  # Flask-Login uses .id (stringifiable)
        self.login = user.login
        self.email = user.email


def _validate_register(login: str, email: str, password: str) -> list[str]:
    errors: list[str] = []
    if not login or not _LOGIN_RE.match(login):
        errors.append("Логин: 3–32 символа, латиница/цифры/underscore/точка (без пробелов).")
    if not email or "@" not in email or len(email) > 254:
        errors.append("Введите корректный email.")
    if not password or len(password) < 8:
        errors.append("Пароль должен быть не короче 8 символов.")
    return errors


@auth_bp.route("/register", methods=["GET", "POST"])
def register():
    login = ""
    email = ""

    if request.method == "POST":
        login = (request.form.get("login") or "").strip()
        email = (request.form.get("email") or "").strip().lower()
        password = request.form.get("password") or ""

        errors = _validate_register(login, email, password)
        if not errors:
            if auth_db.get_user_by_login(login):
                errors.append("Этот логин уже занят.")
            if auth_db.get_user_by_email(email):
                errors.append("Этот email уже зарегистрирован.")

        if errors:
            for e in errors:
                flash(e, "error")
            return render_template("register.html", login=login, email=email)

        try:
            user = auth_db.create_user(login=login, email=email, password=password)
        except Exception:
            # In case of race condition on UNIQUE
            flash("Не удалось создать пользователя (возможно, логин или email уже заняты).", "error")
            return render_template("register.html", login=login, email=email)

        login_user(SessionUser(user))
        auth_db.touch_last_login(user.id)
        flash("Регистрация успешна. Вы вошли в систему.", "success")
        return redirect(url_for("index"))

    return render_template("register.html", login=login, email=email)


@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    login_val = ""

    if request.method == "POST":
        login_val = (request.form.get("login") or "").strip()
        password = request.form.get("password") or ""

        if not login_val or not password:
            flash("Введите логин и пароль.", "error")
            return render_template("login.html", login=login_val)

        user = auth_db.get_user_by_login(login_val)
        if not user or not user.verify_password(password):
            flash("Неверный логин или пароль.", "error")
            return render_template("login.html", login=login_val)

        login_user(SessionUser(user))
        auth_db.touch_last_login(user.id)
        flash("Вы вошли в систему.", "success")
        next_url = request.args.get("next")
        return redirect(next_url or url_for("index"))

    return render_template("login.html", login=login_val)


@auth_bp.route("/logout", methods=["POST"])
@login_required
def logout():
    logout_user()
    flash("Вы вышли из системы.", "success")
    return redirect(url_for("index"))
