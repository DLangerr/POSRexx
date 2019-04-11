PARSE SOURCE . . fullPath
CALL directory filespec('L', fullPath)
conn = getConnection()
IF conn = .false THEN EXIT -1
st = conn~createStatement

testUser = 'INSERT INTO user(Username, Password, Salt, Name, Surname, AccessRights, Active) VALUES ("Filler", "Test", "Test", "Test", "Test", 1, 0)'
products = 'INSERT INTO product(Name, Price, TaxID) VALUES' -
  '("Pizza Pepperoni", 7.8, 4),' -
  '("Pizza Cheese", 7.0, 4),' -
  '("Pizza Margarita", 6.9, 4),' -
  '("Pizza Exotica", 8.0, 4),' -
  '("Pizza Veggie", 7.3, 4),' -
  '("Pizza Fiamma", 7.3, 4),' -
  '("Pizza Salami", 7.0, 4),' -
  '("Garlic Bread", 2.0, 4),' -
  '("Cheese Fries", 3.2, 4),' -
  '("Fries", 2.9, 4),' -
  '("Greek Salad", 4.9, 4),' -
  '("Pineapple Juice", 2.8, 1),' -
  '("Orange Juice", 7.0, 1),' -
  '("Coca Cola", 3.0, 1),' -
  '("Apple Juice", 2.5, 1)' 

selectID = 'SELECT UserID FROM user WHERE Username = "Filler"'
rs = st~executeQuery(selectID)
IF rs~next THEN DO
  id = rs~getString('UserID')
END
ELSE DO
  SAY "Adding new user..."
  st~executeUpdate(testUser)
  SAY "Getting inserted ID..."
  rs = st~executeQuery("SELECT LAST_INSERT_ID()")
  IF rs~next THEN id = rs~getString("LAST_INSERT_ID()")

  SAY "Adding products..."
  st~executeUpdate(products)
END

getFirstProduct = 'SELECT ProductID from product WHERE Name = "Pizza Pepperoni"'
rs = st~executeQuery(getFirstProduct)
IF rs~next THEN firstProductID = rs~getString('ProductID')

ordersToGenerate = 500
PARSE ARG arg1 .
if arg1 <> "" & DATATYPE(arg1) == "NUM" THEN ordersToGenerate = arg1
date = DATE('E')
PARSE VAR date "/" currentMonth "/" currentYear .
currentYear += 2000
DO i=1 TO ordersToGenerate
  SAY "Adding random order number" i || "."
  table = random(1, 15)
  day = random(1, 28)
  CALL newRandom
  DO WHILE year == currentYear & month > currentMonth
    CALL newRandom
  END

  insert = "INSERT INTO orders(DateOfPayment, UserID, TableNumber) VALUES (DATE '" || year || "-" || month || "-" || day || "', " || id || ", " || table || ")"
  st~executeUpdate(insert)
  rs = st~executeQuery("SELECT LAST_INSERT_ID()")
  IF rs~next THEN orderID = rs~getString("LAST_INSERT_ID()")
  DO j=1 TO random(1, 15)
    prodID = random(firstProductID, firstProductID+14)
    insert = "INSERT INTO orderContains(OrderID, ProductID, Status) VALUES ("orderID "," prodID ", 'Paid')"
    st~executeUpdate(insert)
  END
END
SAY "Press enter to quit."
PARSE PULL .
EXIT 0

newRandom:
  month = random(1, 12)
  year = random(currentYear-3, currentYear)
  RETURN

::ROUTINE getConnection
  dbh = .DatabaseHandler~new
  dbh~initSettings("conf.ini")
  success = dbh~connect
  IF success THEN SAY "Connection Successful."
  ELSE DO
    SAY "[-] ERROR: Unable to connect to database."
    SAY "Press enter to quit."
    PARSE PULL .
    RETURN .false
  END
  RETURN dbh~conn

::REQUIRES "setClasspath.rex"
::REQUIRES "DatabaseHandler.CLS"