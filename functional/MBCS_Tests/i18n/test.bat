@echo off
rem Licensed under the Apache License, Version 2.0 (the "License");
rem you may not use this file except in compliance with the License.
rem You may obtain a copy of the License at
rem
rem      https://www.apache.org/licenses/LICENSE-2.0
rem
rem Unless required by applicable law or agreed to in writing, software
rem distributed under the License is distributed on an "AS IS" BASIS,
rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem See the License for the specific language governing permissions and
rem limitations under the License.

SETLOCAL
SET PWD=%~dp0
SET OUTPUT=output.txt
SET CLASSPATH=%PWD%\i18n.jar

call %PWD%\check_env_windows.bat

if exist result rd /S /Q result
mkdir result


%JAVA_BIN%\java %JAVA_OPTIONS% showlocale > result\showlocale.out
%JAVA_BIN%\java %JAVA_OPTIONS% DateFormatTest > result\DateFormatTest.out
%JAVA_BIN%\java %JAVA_OPTIONS% BreakIteratorTest %PWD%\win_%LOCALE%.txt > result\BreakIteratorTest.out

SET FLAG=0

fc %PWD%\expected\win_%LOCALE%\showlocale.out result\showlocale.out > fc_showlocale.out 2>&1
if ErrorLevel 1 ( SET FLAG=1 )
fc %PWD%\expected\win_%LOCALE%\BreakIteratorTest.out result\BreakIteratorTest.out > fc_BreakIteratorTest.out 2>&1
if ErrorLevel 1 ( SET FLAG=1 )
findstr OK result\DateFormatTest.out > find_DateFormatTest.out 2>&1
if ErrorLevel 1 ( SET FLAG=1 )

exit %FLAG%
