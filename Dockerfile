# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.12

# ---------- Stage 1: Builder ----------
FROM python:${PYTHON_VERSION}-slim AS builder

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH=/opt/venv/bin:$PATH

WORKDIR /build

RUN python -m venv /opt/venv

COPY requirements.txt ./

RUN pip install -r requirements.txt


# ---------- Stage 2: Runtime ----------
FROM python:${PYTHON_VERSION}-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/venv/bin:$PATH

WORKDIR /app

RUN groupadd --gid 10001 appgroup \
    && useradd --uid 10001 --gid 10001 \
       --no-create-home \
       --shell /usr/sbin/nologin appuser

COPY --from=builder /opt/venv /opt/venv

COPY --chown=10001:10001 app/ ./app/

COPY --chown=10001:10001 app/ ./app/

COPY --chown=10001:10001 wait_for_db.py ./

USER 10001:10001

EXPOSE 8000

STOPSIGNAL SIGTERM

CMD ["python", "wait_for_db.py"]