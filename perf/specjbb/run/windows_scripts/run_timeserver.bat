::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Sample script for running SPECjbb2015 Time Server.
:: 
:: This sample script demonstrates launching the Time Server on the native host, 
:: ready to communicate with Controller launched on the virtual SUT.
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off

:: Launch command: java [options] -jar specjbb2015.jar -m TIMESERVER [argument] [value] ...

:: Controller host IP to provide connection between Time Server and Controller
:: IP where Multi Controller JVM or Composite JVM is going to be launched
set CTRL_IP=

:: Benchmark options for Time Server
:: Please use -Dproperty=value to override the default and property file value
set SPEC_OPTS=-Dspecjbb.controller.host=%CTRL_IP%

:: Java options for Time Server
set JAVA_OPTS=

:: Optional arguments for Time Server mode
:: For more info please use: java -jar specjbb2015.jar -m <mode> -h
set MODE_ARGS=

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

echo Launching SPECjbb2015 Time Server...
echo.

echo Please launch Multi Controller or Composite JVM on %CTRL_IP% (if not already launched) and monitor its output for progress
@echo on
%JAVA% %SPEC_OPTS% %JAVA_OPTS% -jar specjbb2015.jar -m TIMESERVER %MODE_ARGS% 2>timeserver.log > timeserver.out
@echo off

echo.
echo Time Server has stopped
echo.

exit /b 0
