@echo off
setlocal

echo ========================================
echo  Iniciando Consul e carregando configs
echo ========================================

where consul >nul 2>&1
if errorlevel 1 (
    echo [ERRO] O comando "consul" nao foi encontrado no PATH.
    echo Instale/configure o Consul antes de executar este arquivo.
    pause
    exit /b 1
)

rem Se o agente ainda nao estiver ativo, inicia em modo dev.
consul members >nul 2>&1
if errorlevel 1 (
    echo Iniciando Consul em modo development...
    start "Consul" consul agent -dev
) else (
    echo Consul ja esta em execucao.
)

echo Aguardando o Consul responder na porta 8500...
set /a tentativas=0
:wait_consul
consul members >nul 2>&1
if not errorlevel 1 goto consul_ready
set /a tentativas+=1
if %tentativas% GEQ 20 (
    echo [ERRO] O Consul nao respondeu dentro do tempo esperado.
    pause
    exit /b 1
)
timeout /t 1 /nobreak >nul
goto wait_consul

:consul_ready
echo Consul disponivel. Gravando configuracoes...

rem Currency API - configuracao obrigatoria externalizada no Consul.
consul kv put config/currency-api/server.port "8100"
consul kv put config/currency-api/spring.datasource.url "jdbc:postgresql://localhost:5432/db_currency"
consul kv put config/currency-api/spring.datasource.username "postgres"
consul kv put config/currency-api/spring.datasource.password "admin"

rem Configuracoes ja utilizadas pela Product API.
consul kv put config/product-api/app.promotion.message "Promocao Semana do Cliente"
consul kv put config/product-api,en/app.promotion.message "Christmas Promotion!!!!"

echo.
echo ========================================
echo  Consul configurado com sucesso!
echo ========================================
echo Currency API: porta 8100
 echo Banco: db_currency - localhost:5432
 echo Usuario PostgreSQL: postgres
 echo Consul: localhost:8500
 echo.
echo Para conferir:
echo consul kv get -recurse config/currency-api/
echo.
pause
endlocal
