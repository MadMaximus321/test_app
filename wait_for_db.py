
import os
import time

from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

from app.config import load_settings

settings = load_settings()

timeout = int(os.getenv("DB_WAIT_TIMEOUT", "60"))
interval = 2
deadline = time.monotonic() + timeout

while True:
    try:
        engine = create_engine(
            settings.database_url,
            connect_args={
                "connect_timeout": settings.db_connect_timeout
            }
        )

        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))

        engine.dispose()
        print("PostgreSQL is ready", flush=True)
        break

    except OperationalError:
        print("Waiting for PostgreSQL...", flush=True)

        if time.monotonic() >= deadline:
            print("Database wait timeout exceeded", flush=True)
            raise SystemExit(1)

        time.sleep(min(interval, max(0, deadline - time.monotonic())))

os.execvp("uvicorn", [
    "uvicorn",
    "app.main:app",
    "--host", "0.0.0.0",
    "--port", "8000",
    "--timeout-graceful-shutdown", "65"
])
