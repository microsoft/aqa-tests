:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Sample script for running SPECjbb2015 in Composite mode.
:: 
:: This sample script demonstrates launching the Controller, TxInjector and 
:: Backend in a single JVM.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off

:: Launch command: java [options] -jar specjbb2015.jar -m COMPOSITE [argument] [value] ...

:: Benchmark options (-Dproperty=value to override the default and property file value)
:: Please add -Dspecjbb.controller.host=$CTRL_IP (this host IP) and -Dspecjbb.time.server=true
:: when launching Composite mode in virtual environment with Time Server located on the native host.
set SPEC_OPTS=

:: Java options for Composite JVM
::set JAVA_OPTS=-Xmx28g -Xms28g -Xmn22g -XX:TieredStopAtLevel=1 -XX:+UseSerialGC -Xlog:gc*:file=..\gclogs\sergcfull.txt
set JAVA_OPTS=-Xmx28g -Xms28g -Xmn25g -XX:+UseParallelGC -XX:ParallelGCThreads=1 -Xlog:gc*,gc+ref=debug,gc+phases=debug,gc+age=trace,safepoint:file=../../gclogs/pargc.log -XX:-UseAdaptiveSizePolicy -XX:-UsePerfData -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:LargePageSizeInBytes=1073741824 -Xlog:pagesize=trace:file=pagesize.txt::filecount=0 -Xlog:os=trace:file=os.txt::filecount=0
::set JAVA_OPTS=-Xmx28g -Xms28g -Xmn22g -XX:MetaspaceSize=10g -XX:+UseParallelGC -XX:TieredStopAtLevel=2 -XX:Tier2BackEdgeThreshold=40000 -XX:Tier2CompileThreshold=15000 -XX:-UseBiasedLocking -XX:ParallelGCThreads=32 -Xlog:gc*,gc+task=trace,gc+ref=debug,gc+ergo*=trace,gc+heap=debug:file=..\gclogs\pargcfull-%p-%t.txt -Xlog:safepoint*:file=..\gclogs\pargcfull-safepoints-%p-%t.txt



:: Optional arguments for the Composite mode (-l <num>, -p <file>, -skipReport, etc.)
set MODE_ARGS=-ikv

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

::@set JAVA=C:\projects\jdks\jdk_minimal\bin\java.exe
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
set result=result\%timestamp: =0%
mkdir %result%\config

:: Copy current config to the result directory
copy config %result%\config >nul

cd %result%

echo Run %counter%: %result%
echo Launching SPECjbb2015 in Composite mode...
echo.

echo Start Composite JVM
echo Please monitor %result%\composite.out for progress
@echo on
%JAVA% %SPEC_OPTS% %JAVA_OPTS% -jar ..\..\specjbb2015.jar -m COMPOSITE %MODE_ARGS% 2>composite.log > composite.out
@echo off

echo.
echo Composite JVM has stopped
echo SPECjbb2015 has finished
echo.

cd ..\..

IF %counter% == %NUM_OF_RUNS% GOTO END
set /a counter=%counter + 1
GOTO LOOP
:END

exit /b 0
