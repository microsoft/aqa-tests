@echo off
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Sample script for running SPECjbb2015 in Composite mode.
:: 
:: This sample script demonstrates launching the Controller, TxInjector and 
:: Backend in a single JVM.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Load settings from configuration file
for /F "tokens=1,2 delims==" %%a in (specjbb2015.config) do (
    if "%%a"=="SPEC_OPTS" set SPEC_OPTS=%%b
    if "%%a"=="JAVA_OPTS" set JAVA_OPTS=%%b
    if "%%a"=="MODE_ARGS" set MODE_ARGS=%%b
    if "%%a"=="NUM_OF_RUNS" set NUM_OF_RUNS=%%b
    if "%%a"=="JAVA_PATH" set JAVA=%%b
)

:: Validate JAVA_PATH
@set JAVAPATH=
@for %%J in ("%JAVA%") do (@set JAVAPATH=%%~$PATH:J)
@if not defined JAVAPATH (
    echo ERROR: 'java' executable not found. Ensure JAVA_PATH in specjbb2015config.txt is correct.
    exit /b 1
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: This benchmark requires a JDK7 compliant Java VM.  If such a JVM is not on
:: your path already you must set the JAVA environment variable to point to
:: where the 'java' executable can be found.
::
:: If you are using a JDK9 (or later) Java VM, see the FAQ at:
::                       https://spec.org/jbb2015/docs/faq.html
:: and the Known Issues document at:
::                       https://spec.org/jbb2015/docs/knownissues.html
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Main benchmark execution loop
set /a counter=1
while %counter% leq %NUM_OF_RUNS% do (
    echo Running SPECjbb2015 run #%counter%...

    :: Create result directory based on current timestamp
    set timestamp=%DATE:~-4%-%DATE:~4,2%-%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
    set resultDir=result_%timestamp%
    mkdir "%resultDir%"

    :: Execute the benchmark
    %JAVA% %JAVA_OPTS% -jar specjbb2015.jar -m COMPOSITE %MODE_ARGS% > "%resultDir%\composite_%counter%.log" 2>&1

    echo Run #%counter% completed.
    set /a counter+=1
)

echo All runs completed.
