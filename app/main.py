import os
from contextlib import asynccontextmanager

import psycopg
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse

CONNECTION = {
    "host": os.getenv("DB_HOST", "db"),
    "port": int(os.getenv("DB_PORT", "5432")),
    "dbname": os.environ["DB_NAME"],
    "user": os.environ["DB_USER"],
    "password": os.environ["DB_PASSWORD"],
}


def initialize_database() -> None:
    with psycopg.connect(**CONNECTION) as connection:
        connection.execute(
            """CREATE TABLE IF NOT EXISTS visits (
                   id BIGSERIAL PRIMARY KEY,
                   created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
               )"""
        )


@asynccontextmanager
async def lifespan(_: FastAPI):
    initialize_database()
    yield


app = FastAPI(title="Docker Deployment Demo", version="1.0.0", lifespan=lifespan)


@app.get("/", response_class=HTMLResponse)
def home() -> str:
    return """<!doctype html><html><head><title>Deployment Demo</title></head>
    <body><h1>Docker deployment is running</h1>
    <p>Nginx successfully routed this request to FastAPI.</p>
    <p>Use <code>GET /api/visits</code> and <code>POST /api/visits</code> to verify PostgreSQL.</p>
    </body></html>"""


@app.get("/health")
def health() -> dict[str, str]:
    try:
        with psycopg.connect(**CONNECTION, connect_timeout=2) as connection:
            connection.execute("SELECT 1").fetchone()
    except psycopg.Error as error:
        raise HTTPException(status_code=503, detail="database unavailable") from error
    return {"status": "healthy", "database": "connected"}


@app.get("/api/visits")
def get_visits() -> dict[str, int]:
    with psycopg.connect(**CONNECTION) as connection:
        count = connection.execute("SELECT COUNT(*) FROM visits").fetchone()[0]
    return {"visits": count}


@app.post("/api/visits", status_code=201)
def add_visit() -> dict[str, int]:
    with psycopg.connect(**CONNECTION) as connection:
        visit_id = connection.execute("INSERT INTO visits DEFAULT VALUES RETURNING id").fetchone()[0]
    return {"id": visit_id}
