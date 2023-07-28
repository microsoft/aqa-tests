:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Sample script for running SPECjbb2015 in Distributed mode.
::
:: This sample script demonstrates launching the Backend(s) on the SUT host,
:: ready to communicate with the Controller and TxInjector(s) on an auxiliary
:: host.
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off

:: Launch command: java [options] -jar specjbb2015.jar [argument] [value] ...

:: Number of Groups (TxInjectors mapped to Backend) to expect
set GROUP_COUNT=1

:: Controller host IP to provide connection between agents
set CTRL_IP=

:: Benchmark options for Backend (-Dproperty=value to override the default and property file value)
set SPEC_OPTS_BE=-Dspecjbb.controller.host=%CTRL_IP%

:: Java options for Backend JVM
set JAVA_OPTS_BE=

:: Optional arguments for Backend mode (-d <distribution>, -p <file>, etc.)
set MODE_ARGS_BE=

:: Only update these two fields below in case of running Backends on multiple SUTs.
:: For example, if one plan to run 8 Groups on 2 SUTs then:
::     first SUT setting:  BE_COUNT_START=1 BE_COUNT_END=4
::     second SUT setting: BE_COUNT_START=5 BE_COUNT_END=8

set BE_COUNT_START=1
set BE_COUNT_END=%GROUP_COUNT%

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

@set JAVA=java.exe

@set JAVAPATH=
@for %%J in (%JAVA%) do (@set JAVAPATH=%%~$PATH:J)

@if not defined JAVAPATH (
   echo ERROR: Could not find a 'java' executable. Please set the JAVA environment variable or update the PATH.
   exit /b 1
) else (
   @set JAVA="%JAVAPATH%"
)

echo Controller IP is set to: %CTRL_IP%
echo.

echo Launching SPECjbb2015 in Distributed mode...
echo.

echo Launching Backend JVM(s) on SUT...

set counter=%BE_COUNT_START%
:LOOP

set GROUPID=Group%counter%

echo.
echo Starting JVMs from %GROUPID%:

set JVMID=beJVM
set BE_NAME=%GROUPID%.Backend.%JVMID%
echo Start %BE_NAME%
@echo on
start /b "%BE_NAME%" %JAVA% %JAVA_OPTS_BE% %SPEC_OPTS_BE% -jar specjbb2015.jar -m BACKEND -G=%GROUPID% -J=%JVMID% %MODE_ARGS_BE% > %BE_NAME%.log 2>&1
@echo off

IF %counter% == %BE_COUNT_END% GOTO END

set /a counter=%counter + 1

GOTO LOOP
:END

echo.
echo SPECjbb2015 is running...
echo Please launch Controller and TxInjector JVM(s) on Controller host %CTRL_IP% (if not already launched) and monitor Controller output for progress
echo.

exit /b 0
