@ECHO OFF

SET PGHOST=%1

SET PGPORT=%2

SET PGUSER=%3

SET PGPASSWORD=%4

SET TEMPDIR="%5"

SET DB=%7

"%TEMPDIR%\psql.exe" -d %DB% -l | findstr %6


