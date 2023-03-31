'''
<playlist xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="../../TKG/playlist.xsd">
	<include>../perf.mk</include>
	<test>
		<testCaseName>renaissance-jmh-akka-uct</testCaseName>
		<command>$(JAVA_COMMAND) $(JVM_OPTIONS) -jar $(Q)$(TEST_RESROOT)$(D)renaissance-jmh.jar$(Q) --json $(Q)$(REPORTDIR)$(D)akka-uct.json$(Q) akka-uct; \
		$(TEST_STATUS)</command>
		<levels>
			<level>sanity</level>
		</levels>
		<groups>
			<group>perf</group>
		</groups>
	</test>
</playlist>
'''

benches= ["AkkaUct", "Reactors", "Als", "ChiSquare", "DecTree", "GaussMix", "LogRegression", "MovieLens", "NaiveBayes", "PageRank",
            "FjKmeans", "FutureGenetic", "Mnemonics", "ParMnemonics", "Scrabble", "RxScrabble", "Dotty", "ScalaDoku", "ScalaKmeans", "Philosophers",
            "ScalaStmBench7", "FinagleChirper", "FinagleHttp"]

#forks= [23, 50, 20, 10, 15, 15, 25, 25, 20, 25, 20, 12, 30, 30, 8, 7, 12, 25, 22, 20, 10, 7, 35]
#forks= [8, 17, 7, 4, 5, 5, 8, 8, 7, 8, 7, 4, 10, 10, 2, 2, 4, 8, 7, 7, 4, 2, 12]
forks= [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]

file = open("playlist.xml", "w")
file.write("<?xml version='1.0' encoding='UTF-8'?>")
file.write("""
<!--
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
-->
""")

file.write("<playlist xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"../../TKG/playlist.xsd\">\n")
file.write("\t<include>../perf.mk</include>\n")

for idx, bench in enumerate(benches):
    file.write("\t<test>\n")

    file.write("\t\t<testCaseName>renaissance-jmh-" + bench + "</testCaseName>\n")
    file.write("\t\t<command>\n")
    file.write("\t\t\t$(JAVA_COMMAND) $(ADD_OPENS_CMD) $(JVM_OPTIONS) -Xlog:gc*:file=gc.log -XX:+UseG1GC -Xms12G -Xmx12G -XX:ThreadPriorityPolicy=1 -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseTransparentHugePages")
    file.write(" -jar $(Q)$(TEST_RESROOT)$(D)renaissance-jmh.jar$(Q) -f " + str(forks[idx]) + " -prof gc -bm avgt -rf json -rff $(Q)$(REPORTDIR)$(D)" + bench + ".json$(Q) " + bench + "; $(TEST_STATUS)\n")
    file.write("\t\t</command>\n")
    file.write("\t\t<levels>\n\t\t\t<level>extended</level>\n\t\t</levels>\n\t\t<groups>\n\t\t\t<group>perf</group>\n\t\t</groups>\n")

    file.write("\t</test>\n")

file.write("</playlist>")