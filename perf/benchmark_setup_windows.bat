@echo off

REM ===========================================================
REM Script for Windows System Configuration
REM - NUMA Node Information
REM - Power Mode Configuration
REM ===========================================================

REM Parse command-line arguments
if "%~1"=="" (
    echo No arguments provided. Running both NUMA and Power Mode functions by default...
    call :run_all
    goto :end
) else (
    if "%~1"=="--numa" call :check_numa
    if "%~1"=="--set-performance" call :set_performance
    if "%~1"=="--all" call :run_all
    if "%~1"=="--help" call :show_help
    if not "%~1"=="--help" goto :invalid_option
)

:invalid_option
echo Invalid option provided: %~1
echo Use --help to see the list of valid options.
goto :end

REM Function to display help menu
:show_help
echo ===========================================================
echo HELP MENU
echo ===========================================================
echo Usage: %~n0 [options]
echo Options:
echo   --numa              Check NUMA settings
echo   --set-performance   Set Power Mode to High or Ultimate Performance
echo   --all               Run both NUMA and Power Mode functions (default)
echo   --help              Show this help message
echo ===========================================================
goto :end

REM Function to check NUMA settings
:check_numa
echo ===========================================================
echo Checking NUMA settings...
echo ===========================================================
if exist coreinfo.exe (
    echo Using Coreinfo for NUMA details...
    coreinfo.exe -n | findstr /R "Node"
) else (
    echo Coreinfo not found. Using WMIC instead...
    echo Fetching CPU and system details...
    wmic cpu get NumberOfCores, NumberOfLogicalProcessors, Name
    wmic computersystem get NumberOfProcessors, SystemType
)
echo ===========================================================
goto :end

REM Function to set Power Mode to High or Ultimate Performance
:set_performance
echo ===========================================================
echo Checking Available Power Modes...
echo ===========================================================
powercfg -list

REM Check if Ultimate Performance mode exists
set ULTIMATE_GUID=e9a42b02-d5df-448d-aa00-03f14749eb61
for /f "tokens=4" %%G in ('powercfg -list') do (
    if /i "%%G"=="%ULTIMATE_GUID%" (
        set MODE_FOUND=1
    )
)

if defined MODE_FOUND (
    echo Ultimate Performance mode is already available.
) else (
    echo Ultimate Performance mode not found. Adding it now...
    powercfg -duplicatescheme %ULTIMATE_GUID%
    echo Ultimate Performance mode added successfully.
)

REM Prompt user for selection
echo ===========================================================
choice /c UH /n /m "Choose U for Ultimate Performance or H for High Performance: "
if errorlevel 2 (
    echo Setting High Performance Mode...
    powercfg -setactive SCHEME_MIN
    echo High Performance mode has been set.
)
if errorlevel 1 (
    echo Setting Ultimate Performance Mode...
    powercfg -setactive %ULTIMATE_GUID%
    echo Ultimate Performance mode has been set.
)
echo ===========================================================
goto :end

REM Run both functions
:run_all
echo ===========================================================
echo Running NUMA and Power Mode functions...
echo ===========================================================
call :check_numa
call :set_performance
echo ===========================================================
goto :end

:end
echo ===========================================================
echo Script execution complete. Press any key to exit.
echo ===========================================================
pause > nul