PARSE SOURCE . . fullPath
CALL directory filespec('L', fullPath)

warningCount = 0
fileName = "conf.ini"

classpath = value('CLASSPATH',, 'ENVIRONMENT')
javaHome = value('JAVA_HOME',,'ENVIRONMENT')
path = value('Path',,'ENVIRONMENT')

classpathRequirements = .array~of("mysql-connector-java", "core-3", "javase-3", "slf4j-api", "slf4j-simple", "jfoenix", "jose4j")

DO req OVER classpathRequirements
  IF checkPath(classpath, req) THEN SAY "[+] SUCCESS:" req "found."
  ELSE DO
    SAY "[-] WARNING:" req "not found. CLASSPATH set corretly?"
    warningCount +=1
  END
END


IF checkPath(javaHome, "jdk1.8") | checkPath(path, "jdk1.8") THEN SAY "[+] SUCCESS: Java JDK 1.8 found."
ELSE IF checkPath(javaHome, "jdk") | checkPath(path, "jdk") THEN DO
  SAY "[+] SUCCESS. Java JDK found."
  SAY "[-] WARNING: Java JDK not version 8. Program might not work properly."
  warningCount +=1
END
ELSE DO
  SAY "[-] WARNING: JDK not found. JAVA_HOME / Path set correctly?"
END

DriverManager = bsf.import("java.sql.DriverManager")
System = bsf.import("java.lang.System")
IF System~getProperty("java.version")~startsWith("1.8") THEN SAY "[+] SUCCESS: Java version 1.8 installed correctly."
ELSE DO
  SAY "[-] WARNING: Wrong java version found. This program was made for java 8. Errors might occur."
  warningCount += 1
END

PARSE ARG arg1 arg2 .

editFile = .false
IF arg1 = "" | arg2 = "" THEN DO
  DB_USER = "root"
  DB_PASSWORD = "password"
END
ELSE DO
  editFile = .true
  DB_USER = arg1
  DB_PASSWORD = arg2
END
/* Read settings - Add properties */
IF \SysIsFile(fileName) | editFile THEN DO
  settings = .stream~new(fileName)
  settings~open("both replace")
  settings~lineout('[DATABASE SETTINGS]')
  settings~lineout('DB_NAME = pos_database')
  settings~lineout('DB_USER = ' || DB_USER)
  settings~lineout('DB_PASSWORD = ' || DB_PASSWORD)
  settings~lineout('DB_URL = jdbc:mysql://localhost/')
  settings~lineout('DB_TIMEZONE = CET')
  settings~lineout('DB_USE_SLL = false')
  settings~close
  SAY "[+] SUCCESS: " || fileName || " created."
END

dbh = .DatabaseHandler~new
dbh~initSettings(fileName, .false)

/* establish database connection */
SAY "[+] Connecting to database..."

success = dbh~connect
IF \success THEN CALL connectionError

DB_NAME = dbh~DB_NAME

SAY "[+] SUCCESS: Connected to database."
SAY "[+] Checking if schema exists..."
IF dbh~databaseExists(DB_NAME) THEN DO
  SAY "[+] SUCCESS: Schema " || DB_NAME || " exists."
END
ELSE DO
  SAY "[+] Schema " || DB_NAME || " does not exist."
  SAY "[+] Creating schema..."
  stmt = dbh~conn~createStatement
  SIGNAL ON SYNTAX NAME updateError
  r = stmt~executeUpdate("CREATE DATABASE" DB_NAME)
  SIGNAL OFF SYNTAX
  SAY "[+] SUCCESS: Created schema" DB_NAME
END

dbh~conn~setCatalog(DB_NAME)

tableNames = .array~of("tax", "user", "product", "orders", "orderContains", "businessInformation")
statements = .array~of("CREATE TABLE tax(TaxID TINYINT NOT NULL AUTO_INCREMENT, TaxRate DECIMAL(3, 3) NOT NULL, PRIMARY KEY (TaxID)) CHARACTER SET = utf8mb4", -
"CREATE TABLE user(UserID INT NOT NULL AUTO_INCREMENT, Username VARCHAR(20) NOT NULL, Password VARCHAR(40) NOT NULL, Salt VARCHAR(35) NOT NULL, Name VARCHAR(20) NOT NULL, Surname VARCHAR(20) NOT NULL, AccessRights TINYINT(1) NOT NULL, DateOfLastLogin DATETIME NULL, Active TINYINT NOT NULL DEFAULT 1, UNIQUE(Username), PRIMARY KEY(UserID)) CHARACTER SET = utf8mb4", -
"CREATE TABLE product(ProductID INT NOT NULL AUTO_INCREMENT, Name VARCHAR(30) NOT NULL, Price DECIMAL(10, 2) NOT NULL, Availability TINYINT NOT NULL DEFAULT 1, TaxID TINYINT NOT NULL, PRIMARY KEY (ProductID), FOREIGN KEY(TaxID) REFERENCES tax(TaxID)) CHARACTER SET = utf8mb4", -
"CREATE TABLE orders(OrderID INT NOT NULL AUTO_INCREMENT, DateOfPayment DATETIME NULL, UserID INT NOT NULL, TableNumber VARCHAR(15) NOT NULL, JwsHeader VARCHAR(30) NULL, JwsPayload VARCHAR(200) NULL, JwsSignature VARCHAR(100) NULL, PRIMARY KEY (OrderID), FOREIGN KEY(UserID) REFERENCES user(userID)) CHARACTER SET = utf8mb4", -
"CREATE TABLE orderContains(TempID INT NOT NULL AUTO_INCREMENT, OrderID INT NOT NULL, ProductID INT NOT NULL, Status VARCHAR(15) NOT NULL, PRIMARY KEY (TempID), FOREIGN KEY (OrderID) REFERENCES orders(OrderID), FOREIGN KEY (ProductID) REFERENCES product(ProductID)) CHARACTER SET = utf8mb4", -
"CREATE TABLE businessInformation(Name VARCHAR(35) NOT NULL, Postcode VARCHAR(10) NOT NULL, City VARCHAR(35) NOT NULL, Address VARCHAR(45) NOT NULL, PhoneNumber VARCHAR(25) NOT NULL, Email VARCHAR(35) NOT NULL, VatID VARCHAR(35) NOT NULL, CashRegisterID VARCHAR(30) NOT NULL, CertSerialNumber VARCHAR(45) NOT NULL, AES256Key VARCHAR(44) NOT NULL, PrivateKey VARCHAR(100) NOT NULL, PRIMARY KEY (Name)) CHARACTER SET = utf8mb4")

DO i=1 to tableNames~size
  IF \dbh~tableExists(tableNames[i], DB_NAME) THEN DO
    SAY "[+] Creating table" tableNames[i] || "..."
    stmt = dbh~conn~createStatement
    SIGNAL ON SYNTAX NAME createTableError
    stmt~execute(statements[i])
    SIGNAL OFF SYNTAX
    SAY "[+] SUCCESS: Table" tableNames[i] "created."
  END
  ELSE SAY "[+]" tableNames[i] "table exists already."
END

taxInsert = "INSERT INTO tax(taxRate) VALUES (0.2), (0.19), (0.13), (0.1), (0)"
stmt = dbh~conn~createStatement
SIGNAL ON SYNTAX NAME createTableError
stmt~execute(taxInsert)
SIGNAL OFF SYNTAX

SAY "================================================"
SAY "[+] Setup completed." warningCount "warning(s) found."
SAY "Press enter to quit."
PARSE PULL .
EXIT 0

connectionError:
  SAY "[-] ERROR: Failed connecting to database."
  SAY "[-] ERROR: Verify" fileName
  CALL quit

updateError:
  SAY "[-] ERROR: Failed updating database."
  CALL quit

createTableError:
  SAY "[-] ERROR: Failed creating table."
  CALL quit

quit:
  SAY "[-] ERROR: Quitting program."
  SAY "================================================"
  SAY "[-] Setup unsuccessful."
  SAY "Press enter to quit."
  PARSE PULL . 
  EXIT -1

    
::ROUTINE checkPath
  USE ARG path, fileName
  IF POS(fileName, path) <> 0 THEN RETURN .true
  ELSE RETURN .false

::REQUIRES "setClasspath.rex"
::REQUIRES "BSF.CLS"
::REQUIRES "DatabaseHandler.CLS"
