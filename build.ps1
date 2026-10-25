Set-Location $PSScriptRoot

$build = Join-Path $PSScriptRoot "build"
$package = Join-Path $build "package"

if (Test-Path $package) { Remove-Item -Recurse -Force $package }
New-Item -ItemType Directory -Force $package | Out-Null

uv export --frozen --no-dev --no-hashes --no-emit-project -o (Join-Path $build "requirements.txt")
if ($LASTEXITCODE -ne 0) { throw "uv export failed" }

uv pip install `
    -r (Join-Path $build "requirements.txt") `
    --target $package `
    --python-platform x86_64-manylinux2014 `
    --python-version 3.13 `
    --only-binary :all:
if ($LASTEXITCODE -ne 0) { throw "uv pip install failed" }

Copy-Item -Recurse (Join-Path $PSScriptRoot "app") (Join-Path $package "app")
Get-ChildItem -Recurse -Directory -Filter __pycache__ $package | Remove-Item -Recurse -Force

Write-Host "Lambda package ready: $package"
