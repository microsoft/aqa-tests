:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Sample script for running SPECjbb2015 in Distributed mode.
::
:: This sample script demonstrates launching the Controller and TxInjector(s)
:: on an auxiliary host, ready to communicate with Backend(s) launched on a
:: separate SUT host.
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off

:: Launch command: java [options] -jar specjbb2015.jar [argument] [value] ...

:: Number of Groups (TxInjectors mapped to Backend) to expect
set GROUP_COUNT=1

:: How many TxInjector JVMs to expect in each Group
set TI_JVM_COUNT=1

:: Controller host IP to provide connection between agents
set CTRL_IP=

:: Benchmark options for Controller / TxInjector 
:: Please use -Dproperty=value to override the default and property file value
set SPEC_OPTS_C=-Dspecjbb.controller.host=%CTRL_IP% -Dspecjbb.group.count=%GROUP_COUNT% -Dspecjbb.txi.pergroup.count=%TI_JVM_COUNT%
set SPEC_OPTS_TI=-Dspecjbb.controller.host=%CTRL_IP%

:: Java options for Controller / TxInjector JVM
set JAVA_OPTS_C=
set JAVA_OPTS_TI=

:: Optional arguments for distController / TxInjector mode
:: For more info please use: java -jar specjbb2015.jar -m <mode> -h
set MODE_ARGS_C=
set MODE_ARGS_TI=

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

:: Create result directory
set timestamp=%DATE:~12,2%-%DATE:~4,2%-%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
set result=%timestamp: =0%
mkdir %result%\config

:: Copy current config to the result directory
copy config %result%\config >nul

cd %result%

echo Run: %result%
echo Controller IP (this host IP) is set to: %CTRL_IP%
echo.

echo Launching SPECjbb2015 in Distributed mode...

set counter=0
:LOOP
set /a counter=%counter + 1

set GROUPID=Group%counter%

echo.
echo Starting JVMs from %GROUPID%:

set ticounter=0
:LOOPTI
set /a ticounter=%ticounter + 1

set JVMID=txiJVM%ticounter%
set TI_NAME=%GROUPID%.TxInjector.%JVMID%
echo Start %TI_NAME%
@echo on
start /b "%TI_NAME%" %JAVA% %JAVA_OPTS_TI% %SPEC_OPTS_TI% -jar ..\specjbb2015.jar -m TXINJECTOR -G=%GROUPID% -J=%JVMID% %MODE_ARGS_TI% > %TI_NAME%.log 2>&1
@echo off

IF %ticounter% == %TI_JVM_COUNT% GOTO ENDTI
GOTO LOOPTI
:ENDTI

IF %counter% == %GROUP_COUNT% GOTO END
GOTO LOOP
:END

echo.
echo Start Controller JVM
echo Please launch Backend JVM(s) on SUT (if not already launched) and monitor %result%\controller.out for progress
@echo on
%JAVA% %JAVA_OPTS_C% %SPEC_OPTS_C% -jar ..\specjbb2015.jar -m DISTCONTROLLER %MODE_ARGS_C% 2>controller.log > controller.out
@echo off

echo.
echo Controller JVM has stopped
echo SPECjbb2015 has finished
echo.

cd ..

exit /b 0
