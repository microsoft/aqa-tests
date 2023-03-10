/*******************************************************************************
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      https://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*******************************************************************************/

import org.junit.*;
import static org.junit.Assert.*;

import java.time.chrono.JapaneseDate;
import java.time.ZoneId;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.LinkOption;
import java.nio.file.attribute.FileTime;
import java.nio.file.FileStore;
import java.io.IOException;
import java.io.File;

public class FileTest{
    private Path tempPath;
    private long version = 0L;
    private int fileTimeLen;
    private final static int EPOC_20000101 = 946684800; //Epoc of 2000-0101T00:00:00
    private final static int NANOS_LEN  = "2000-01-01T00:00:01.001001001Z".length();
    private final static int MICROS_LEN = "2000-01-01T00:00:01.001001Z".length();
    private final static int MILLIS_LEN = "2000-01-01T00:00:01.001Z".length();

    @Before
    public void generate() {
        try{
            tempPath = Files.createTempFile(Paths.get("."), "FT", "");
            Instant ins = Instant.ofEpochSecond(EPOC_20000101)
                                 .plusNanos(1_001_001_001);
            Files.setLastModifiedTime(tempPath, FileTime.from(ins));
            FileTime ft = Files.getLastModifiedTime(tempPath,
                              LinkOption.NOFOLLOW_LINKS);
            Instant after = ft.toInstant();
            fileTimeLen = after.toString().length();
        }catch(IOException e) {
            e.printStackTrace();
        }
        version = JavaVersion.getVersion();
    }
    @After
    public void cleanup() {
        File file = tempPath.toFile();
        if (file != null && file.exists()) {
            file.delete();
        }
    }

    @Test
    public void check() throws Exception {
        FileTime ft = Files.getLastModifiedTime(tempPath,
                          LinkOption.NOFOLLOW_LINKS);
        Instant ins = ft.toInstant();
        isEqualTimeString(ft.toString(), ins.toString());
        //assertNotEquals(ft, ins); // FileTime and Instant are different
        assertFalse(ft.equals(ins)); // FileTime and Instant are different

        FileTime ft2 = FileTime.from(ins);
        assertEquals(ft, ft2);

        Instant ins2 = ins.plusNanos(1);
        //assertNotEquals(ins, ins2);
        assertFalse(ins.equals(ins2));
        //assertNotEquals(ft, FileTime.from(ins2));
        assertFalse(ft.equals(FileTime.from(ins2)));

        Instant ins3 = ins.plusMillis(1);
        //assertNotEquals(ins, ins3);
        assertFalse(ins.equals(ins3));
        //assertNotEquals(ft, FileTime.from(ins3));
        assertFalse(ft.equals(FileTime.from(ins3)));

        assertEquals(ft.toMillis(), ins.toEpochMilli());
    }

    @Test
    public void modifyTest() throws Exception {
        FileStore store = Files.getFileStore(tempPath);
        String type = store.type();
        System.out.println("FS="+type);

        FileTime ft = Files.getLastModifiedTime(tempPath,
                          LinkOption.NOFOLLOW_LINKS);
        Instant ins = ft.toInstant();

        Instant insplus = ins.plusNanos(1);
        Files.setLastModifiedTime(tempPath, FileTime.from(insplus));
        ft = Files.getLastModifiedTime(tempPath,
                          LinkOption.NOFOLLOW_LINKS);

        if (version >= 14_000_000L) {
            // JDK-8181493 enhanced to support nano seconds.
            if (fileTimeLen >= NANOS_LEN) {
                assertEquals(ft.toInstant(), insplus);
            }
        } else {
            assertFalse(ft.toString().equals(insplus.toString())); // No nano second support in file
        }

        if (fileTimeLen >= MICROS_LEN) {
            insplus = ins.plus(1L, ChronoUnit.MICROS);
            Files.setLastModifiedTime(tempPath, FileTime.from(insplus));
            ft = Files.getLastModifiedTime(tempPath,
                              LinkOption.NOFOLLOW_LINKS);
            isEqualTimeString(ft.toString(), insplus.toString());
        }

        if (fileTimeLen >= MILLIS_LEN) {
            insplus = ins.plusMillis(1);
            Files.setLastModifiedTime(tempPath, FileTime.from(insplus));
            ft = Files.getLastModifiedTime(tempPath,
                              LinkOption.NOFOLLOW_LINKS);
            isEqualTimeString(ft.toString(), insplus.toString());
        }

        insplus = ins.plusSeconds(1);
        Files.setLastModifiedTime(tempPath, FileTime.from(insplus));
        ft = Files.getLastModifiedTime(tempPath,
                          LinkOption.NOFOLLOW_LINKS);
        if (type.indexOf("FAT") != -1){
            // Skip: FAT16/FAT32/exFAT support 2-second intervals
        }else{
            isEqualTimeString(ft.toString(), insplus.toString());
        }
    }

    @Test
    public void InstantTest(){
        Instant ins = Instant.ofEpochSecond(0);
        assertEquals("1970-01-01T00:00:00Z", ins.toString());
        FileTime ft = FileTime.from(ins);
        assertEquals("1970-01-01T00:00:00Z", ft.toString());

        Instant insplus = ins.plusNanos(10);
        // Instant.toString specify digits number should be 0,3,6,or 9.
        assertEquals("1970-01-01T00:00:00.000000010Z", insplus.toString());
        ft = FileTime.from(insplus);
        // FileTime.toString specify digits number should be more than 1.
        assertEquals("1970-01-01T00:00:00.00000001Z", ft.toString());

        insplus = ins.plus(10, ChronoUnit.MICROS);
        assertEquals("1970-01-01T00:00:00.000010Z", insplus.toString());
        ft = FileTime.from(insplus);
        assertEquals("1970-01-01T00:00:00.00001Z", ft.toString());

        insplus = ins.plusMillis(10);
        assertEquals("1970-01-01T00:00:00.010Z", insplus.toString());
        ft = FileTime.from(insplus);
        assertEquals("1970-01-01T00:00:00.01Z", ft.toString());
    }

    // FileTime and Instant have different format style,
    // since less than second unit is extension of ISO8601.
    // This method compares them.
    private void isEqualTimeString(String t1, String t2) {
        int l1 = t1.length();
        int l2 = t2.length();
        if (l1 == l2) {
            assertEquals(t1.toString(), t2.toString());
            return;
        } else {
            // Remove last "Z" (Timezon UTC)
            String t1z = t1.substring(0, l1 - 1);
            String t2z = t2.substring(0, l2 - 1);
            // Fill "0"
            if (l1 > l2) {
                while(l1-1 != t2z.length()){
                    t2z += "0";
                }
            } else {
                while(l2-1 != t1z.length()){
                    t1z += "0";
                }
            }
            assertEquals(t1z.toString(), t2z.toString());
            return;
        }
    }
}

