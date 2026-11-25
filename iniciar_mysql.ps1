# Prepara el entorno local y abre Flask en primer plano. No lee .env.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$pythonBanco = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $pythonBanco)) {
    py -3 -m venv .venv
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el entorno Python.' }
}
& $pythonBanco -c "import importlib.util as u,sys;sys.exit(0 if u.find_spec('flask') and u.find_spec('mysql') and u.find_spec('mysql.connector') and u.find_spec('tzdata') else 1)"
if ($LASTEXITCODE -ne 0) {
    & $pythonBanco -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron instalar las dependencias.' }
}
$configBanco = Join-Path $PSScriptRoot 'mysql.local.json'
if (-not (Test-Path -LiteralPath $configBanco)) {
    $usuarioBanco = Read-Host 'Usuario MySQL (Enter para root)'
    if (-not $usuarioBanco) { $usuarioBanco = 'root' }
    $claveSeguraBanco = Read-Host 'Contraseña MySQL (no se muestra)' -AsSecureString
    $punteroBanco = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($claveSeguraBanco)
    try {
        $configuracionBanco = @{host='127.0.0.1';port=3306;user=$usuarioBanco;password=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($punteroBanco);database='sistema_banco_mysql'}
        $jsonBanco = $configuracionBanco | ConvertTo-Json
        [IO.File]::WriteAllText($configBanco,$jsonBanco,[Text.UTF8Encoding]::new($false))
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($punteroBanco)
        $configuracionBanco=$null;$jsonBanco=$null;$claveSeguraBanco=$null
    }
}
& $pythonBanco scripts/preparar_mysql.py
if ($LASTEXITCODE -ne 0) { throw 'Revisa la conexión al servicio MySQL. No se inició Flask.' }
Write-Host 'Abre http://127.0.0.1:5000. Para detener: Ctrl+C.'
& $pythonBanco run.py
