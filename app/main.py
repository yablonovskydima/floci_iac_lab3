import json
import os

import boto3
from botocore.config import Config
from fastapi import FastAPI, HTTPException, Query
from mangum import Mangum
from pydantic import BaseModel

BUCKET_NAME = os.environ.get("BUCKET_NAME", "books-api-data")
BOOKS_KEY = os.environ.get("BOOKS_KEY", "books.json")

s3 = boto3.client("s3", config=Config(s3={"addressing_style": "path"}))

app = FastAPI(title="Books API", version="1.0.0")


class Book(BaseModel):
    id: int
    title: str
    author: str
    year: int


class BooksResponse(BaseModel):
    count: int
    source: str
    items: list[Book]


def load_books() -> list[Book]:
    try:
        obj = s3.get_object(Bucket=BUCKET_NAME, Key=BOOKS_KEY)
    except s3.exceptions.NoSuchKey:
        raise HTTPException(status_code=404, detail=f"s3://{BUCKET_NAME}/{BOOKS_KEY} not found")
    return [Book(**item) for item in json.loads(obj["Body"].read())]


@app.get("/books", response_model=BooksResponse)
def list_books(
    author: str | None = Query(None),
    limit: int = Query(100, ge=1, le=100),
) -> BooksResponse:
    books = load_books()
    if author:
        books = [b for b in books if author.lower() in b.author.lower()]
    books = books[:limit]
    return BooksResponse(count=len(books), source=f"s3://{BUCKET_NAME}/{BOOKS_KEY}", items=books)


handler = Mangum(app, lifespan="off")
