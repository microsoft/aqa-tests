:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Sample script for running SPECjbb2015 in MultiJVM mode.
:: 
:: This sample script demonstrates running the Controller, TxInjector(s) and 
:: Backend(s) in separate JVMs on the same server.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off

:: Launch command: java [options] -jar specjbb2015.jar [argument] [value] ...

:: Number of Groups (TxInjectors mapped to Backend) to expect
set GROUP_COUNT=1

:: Number of TxInjector JVMs to expect in each Group
set TI_JVM_COUNT=1

:: Benchmark options for Controller / TxInjector / Backend
:: Please use -Dproperty=value to override the default and property file value
:: Please add -Dspecjbb.controller.host=$CTRL_IP (this host IP) to the benchmark options for the all components
:: and -Dspecjbb.time.server=true to the benchmark options for Controller 
:: when launching MultiJVM mode in virtual environment with Time Server located on the native host.
set SPEC_OPTS_C=-Dspecjbb.group.count=%GROUP_COUNT% -Dspecjbb.txi.pergroup.count=%TI_JVM_COUNT%
set SPEC_OPTS_TI=
set SPEC_OPTS_BE=

:: Java options for Controller / TxInjector / Backend JVM
set JAVA_OPTS_C=
set JAVA_OPTS_TI=
set JAVA_OPTS_BE=

:: Optional arguments for multiController / TxInjector / Backend mode 
:: For more info please use: java -jar specjbb2015.jar -m <mode> -h
set MODE_ARGS_C=
set MODE_ARGS_TI=
set MODE_ARGS_BE=

:: Number of successive runs
set NUM_OF_RUNS=1

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

set counter=1
:LOOP

:: Create result directory
set timestamp=%DATE:~12,2%-%DATE:~4,2%-%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
set result=%timestamp: =0%
mkdir %result%\config

:: Copy current config to the result directory
copy config %result%\config >nul

cd %result%

echo Run %counter%: %result%
echo Launching SPECjbb2015 in MultiJVM mode...

set groupcounter=1
:LOOP_GROUP

set GROUPID=Group%groupcounter%

echo.
echo Starting JVMs from %GROUPID%:

set ticounter=1
:LOOP_TI

set JVMID=txiJVM%ticounter%
set TI_NAME=%GROUPID%.TxInjector.%JVMID%
echo Start %TI_NAME%
@echo on
start /b "%TI_NAME%" %JAVA% %JAVA_OPTS_TI% %SPEC_OPTS_TI% -jar ..\specjbb2015.jar -m TXINJECTOR -G=%GROUPID% -J=%JVMID% %MODE_ARGS_TI% > %TI_NAME%.log 2>&1
@echo off

IF %ticounter% == %TI_JVM_COUNT% GOTO END_TI
set /a ticounter=%ticounter + 1
GOTO LOOP_TI
:END_TI

set JVMID=beJVM
set BE_NAME=%GROUPID%.Backend.%JVMID%
echo Start %BE_NAME%
@echo on
start /b "%BE_NAME%" %JAVA% %JAVA_OPTS_BE% %SPEC_OPTS_BE% -jar ..\specjbb2015.jar -m BACKEND -G=%GROUPID% -J=%JVMID% %MODE_ARGS_BE% > %BE_NAME%.log 2>&1
@echo off

IF %groupcounter% == %GROUP_COUNT% GOTO END_GROUP
set /a groupcounter=%groupcounter + 1
GOTO LOOP_GROUP
:END_GROUP

echo.
echo Start Controller JVM
echo Please monitor %result%\controller.out for progress
@echo on
%JAVA% %JAVA_OPTS_C% %SPEC_OPTS_C% -jar ..\specjbb2015.jar -m MULTICONTROLLER %MODE_ARGS_C% 2>controller.log > controller.out
@echo off

echo.
echo Controller JVM has stopped
echo SPECjbb2015 has finished
echo.

cd ..

IF %counter% == %NUM_OF_RUNS% GOTO END
set /a counter=%counter + 1
GOTO LOOP
:END

exit /b 0
