@echo off

echo DEBUG - Inizio script
echo Directory iniziale: %CD%

cd /d "%~dp0"
echo Directory dopo cd: %CD%

if exist "package.json" (
    echo SUCCESSO - package.json trovato
) else (
    echo ERRORE - package.json non trovato
    echo Contenuto directory:
    dir
)

pause