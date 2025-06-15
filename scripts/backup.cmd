@echo off
:: Set tanggal dan waktu (format: YYYY-MM-DD_HH-MM-SS)
for /f "tokens=1-4 delims=/ " %%a in ("%date%") do (
    set YYYY=%%d
    set MM=%%b
    set DD=%%c
)
for /f "tokens=1-3 delims=:. " %%a in ("%time%") do (
    set HH=%%a
    set Min=%%b
    set Sec=%%c
)

:: Hilangkan spasi di jam jika <10
if "%HH:~0,1%"==" " set HH=0%HH:~1,1%

:: Lokasi file backup
set FILE_BACKUP=C:\laragon\www\arthub-auction\backups\arthub_%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%.sql


:: Jalankan mysqldump untuk database arthub_db
mysqldump -u root --routines arthub_db > "%FILE_BACKUP%"

echo Backup selesai: %FILE_BACKUP%
pause
