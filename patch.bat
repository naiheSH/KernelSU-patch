@echo off
chcp 65001 >nul
setlocal
set PATH=%PATH%;%~dp0bin
echo. GKI版本选择，依据系统内核显示版本号
echo       1. android 12-5.10
echo       2. android 13-5.10
echo       3. android 13-5.15
echo       4. android 14-5.15
echo       5. android 14-6.1
echo       6. android 15-6.6
echo.______________________________
set /p choice= (1-6):

if "%choice%" == "1" (
    ksud boot-patch -b img\boot.img -m ko\android12-5.10_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi android12-5.10
) else if "%choice%" == "2" (
    ksud boot-patch -b img\init_boot.img -m ko\android13-5.10_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi android13-5.10
) else if "%choice%" == "3" (
    ksud boot-patch -b img\init_boot.img -m ko\android13-5.15_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi android13-5.15
) else if "%choice%" == "4" (
    ksud boot-patch -b img\init_boot.img -m ko\android14-5.15_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi android14-5.15
) else if "%choice%" == "5" (
    ksud boot-patch -b img\init_boot.img -m ko\android14-6.1_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi android14-6.1
) else if "%choice%" == "6" (
    ksud boot-patch -b img\init_boot.img -m ko\android15-6.6_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi ndroid15-6.6
) else (
    echo 无效的选择
    exit /b 1
)

echo 是否删除 img 文件夹中的所有文件? (y/n)
set /p del_choice=

if /i "%del_choice%" == "y" (
    REM 删除 img 文件夹中的所有文件
    del /Q img\*
    echo img 文件夹中的所有文件已删除
) else (
    echo img 文件夹中的文件未删除
)

pause
endlocal