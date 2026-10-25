A minimal API service with a single `GET /books` endpoint:

- **API Gateway (REST)** receives the HTTP request and forwards it to Lambda.
- **Lambda** runs a **FastAPI** app wrapped with **Mangum**.
- **S3** stores the data (`books-api-data/books.json`).

All infrastructure is described in **Terraform** and deployed to the local AWS emulator Floci

## API link

After `terraform apply`, the link is shown in the outputs (the API id is generated on creation):

```
api_url       = "http://localhost:4566/restapis/d13bcb1983/dev/_user_request_/books"
api_url_vhost = "http://d13bcb1983.execute-api.localhost.floci.io:4566/dev/books"
```

## API description

### `GET /books`

Returns the list of books. The data is read from the S3 object `s3://books-api-data/books.json` on every request.

**200 OK**

```json
{
  "count": 1,
  "source": "s3://books-api-data/books.json",
  "items": [
    { "id": 3, "title": "Lisova pisnia", "author": "Lesia Ukrainka", "year": 1911 }
  ]
}
```

## Deploy

```bash
floci start
```

```powershell
.\build.ps1
```

```bash
terraform -chdir=terraform init
```

```bash
terraform -chdir=terraform apply -auto-approve
```

`build.ps1` exports the dependencies from `uv.lock` and installs them with `uv pip install --python-platform x86_64-manylinux2014 --python-version 3.13`, so the package contains Linux wheels (e.g. `pydantic_core`) even when built on Windows. Terraform zips `build/package`, uploads the zip to S3 and creates the Lambda from `s3_bucket`/`s3_key`.