PARSE SOURCE . . fullPath
homeDir = filespec('Location',fullPath)
osVer = SysVersion()
os = lower(left(osVer, 1))

IF os <> 'w' & os <> 'l' THEN DO
  SAY "[-] WARNING: For operating systems other than Windows and Linux the classpath has to be set manually."
  RETURN 
END

SELECT
  WHEN os == 'w' THEN binDir = homeDir || "bin\"
  WHEN os == 'l' THEN binDir = homeDir || "bin/"
END

CALL SysFileTree binDir, "file", "O"

DO i=1 TO file.0
  IF POS(".jar", lower(file.i)) > 0 THEN DO
    SELECT
      WHEN os == 'w' THEN "set CLASSPATH=%CLASSPATH%;" || file.i
      WHEN os == 'l' THEN "export CLASSPATH=$CLASSPATH:" || file.i
      OTHERWISE
    END
  END
END

