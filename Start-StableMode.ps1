$entryPoint = Join-Path $PSScriptRoot 'Antigravity稳定模式.ps1'
& $entryPoint @args
exit $LASTEXITCODE
