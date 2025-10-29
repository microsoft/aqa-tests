:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Sample script for running SPECjbb2015 reporter with different level of details
::
:: Usage:
::
::    run_reporter.bat <binary log file name> <level of report details>
::
:: Examples:
::
::     1)  run_reporter.bat specjbb2015-D-20150111-00001.data.gz 3
::     2)  run_reporter.bat C:\specjbb2015\specjbb2015-C-20150128-00001.data.gz 2
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off

:: Launch command: java [options] -jar specjbb2015.jar [argument] [value] ...

:: Java options for Reporter JVM
set JAVA_OPTS=

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: This benchmark requires a JDK7 compliant Java VM. If such a JVM is not on
:: your path already you must set the JAVA environment variable to point to
:: where the 'java' executable can be found.
::
:: If you are using a JDK9 (or later) Java VM, see the FAQ at:
::                       https://spec.org/jbb2015/docs/faq.html
:: and the Known Issues document at:
::                       https://spec.org/jbb2015/docs/knownissues.html
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@set JAVA=java.exe

@set JAVAPATH=
@for %%J in (%JAVA%) do (@set JAVAPATH=%%~$PATH:J)

@if not defined JAVAPATH (
   echo ERROR: Could not find a 'java' executable. Please set the JAVA environment variable or update the PATH.
   exit /b 1
) else (
   @set JAVA="%JAVAPATH%"
)

echo Run command: run_reporter.bat ^<binary_log_file^> ^<report_details_level^>
echo.
echo Binary log file name: %1
echo Report details level: %2

IF NOT EXIST "%1" (
    echo ERROR: No such file %1
    exit /b 1
)

echo.
echo Running SPECjbb2015 reporter...
@echo on
%JAVA% %JAVA_OPTS% -jar specjbb2015.jar -m REPORTER -s %1 -l %2 > reporter.log 2>&1
:: if config/SPECjbb2015.prop files not there in default location user must define -p <property file> on the above launch command line
@echo off

echo.
echo Reporter has finished

exit /b 0
