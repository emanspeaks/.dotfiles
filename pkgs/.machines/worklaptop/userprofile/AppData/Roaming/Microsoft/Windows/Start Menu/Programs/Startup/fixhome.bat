@REM Suppress the prompt with /f (force)
reg delete "HKCU\Volatile Environment" /v HOMEDRIVE /f
reg delete "HKCU\Volatile Environment" /v HOMEPATH /f
reg delete "HKCU\Volatile Environment" /v HOMESHARE /f

setx HOMEDRIVE "C:"
setx HOMEPATH "\Users\%USERNAME%"
setx HOMESHARE ""

@REM taskkill /f /im explorer.exe
@REM start explorer.exe
