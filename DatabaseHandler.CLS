/**
  * DatabaseHandler Class stores, updates and retrieves data from the database
*/

::CLASS DatabaseHandler PUBLIC
::METHOD conn ATTRIBUTE
::METHOD DB_URL ATTRIBUTE
::METHOD DB_NAME ATTRIBUTE
::METHOD DriverManager ATTRIBUTE
::METHOD FXCollections ATTRIBUTE
::METHOD properties ATTRIBUTE
::METHOD init
  EXPOSE DriverManager FXCollections settings
  DriverManager = bsf.import("java.sql.DriverManager")
  FXCollections = bsf.import("javafx.collections.FXCollections")

::METHOD initSettings PUBLIC
  EXPOSE properties DB_URL DB_NAME
  USE ARG fileName, withSchema=.true

  properties = .bsf~new("java.util.Properties")
  settings = .stream~new(fileName)~~open
  DO line OVER settings
    PARSE VAR line key "=" .
    PARSE VAR line "=" setting .
    key = key~strip
    setting = setting~strip
    SELECT
      WHEN key = "DB_USER" THEN properties~put("user", setting)
      WHEN key = "DB_PASSWORD" THEN properties~put("password", setting)
      WHEN key = "DB_TIMEZONE" THEN properties~put("serverTimezone", setting)
      WHEN key = "DB_USE_SLL" THEN properties~put("useSSL", setting)
      WHEN key = "DB_URL" THEN DB_URL = setting
      WHEN key = "DB_NAME" THEN DB_NAME = setting
      OTHERWISE 
    END
  END
  settings~close
  IF withSchema THEN DO 
    DB_URL = DB_URL || DB_NAME
  END

::METHOD connect PUBLIC
  EXPOSE DriverManager DB_URL properties conn

  SIGNAL ON SYNTAX NAME connectionError
  conn = DriverManager~getConnection(DB_URL, properties)
  SIGNAL OFF SYNTAX

  RETURN .true

connectionError: /* Connection failed - show error text */
  RETURN .false


::METHOD rootUserExists PUBLIC
  EXPOSE conn
  statement = conn~createStatement
  queryResults = statement~executeQuery("SELECT * FROM user WHERE accessRights=4")
  IF queryResults~next THEN DO -- Query returned something = Root User Exists
    RETURN .true
  END
  RETURN .false -- No root user found

::METHOD bizInfExists PUBLIC
  EXPOSE conn
  statement = conn~createStatement
  queryResults = statement~executeQuery("SELECT Name FROM businessInformation")
  IF queryResults~next THEN DO -- Entry for business informations exists
    RETURN .true
  END
  RETURN .false -- No information found

::METHOD removeBizInf PUBLIC
  EXPOSE conn
  query = "DELETE FROM businessInformation"
  prepStatement = conn~prepareStatement(query)
  prepStatement~execute

::METHOD addBusinessInformation PUBLIC
  EXPOSE conn
  USE ARG name, postcode, city, address, number, email, vatID, cashRegID, certSerialNr, aes256, priv
  query = "INSERT INTO businessInformation VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, name)
  prepStatement~setString(2, postcode)
  prepStatement~setString(3, city)
  prepStatement~setString(4, address)
  prepStatement~setString(5, number)
  prepStatement~setString(6, email)
  prepStatement~setString(7, vatID)
  prepStatement~setString(8, cashRegID)
  prepStatement~setString(9, certSerialNr)
  prepStatement~setString(10, aes256)
  prepStatement~setString(11, priv)
  prepStatement~execute

::METHOD loadUserInformation PUBLIC
  EXPOSE conn
  USE ARG username
  query = "SELECT UserID, Name, Surname, AccessRights FROM user WHERE Username = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, username)
  queryResults = prepStatement~executeQuery

  IF queryResults~next THEN DO
    userID = queryResults~getString("UserID")
    name = queryResults~getString("Name")
    surname = queryResults~getString("Surname")
    accessRights = queryResults~getString("AccessRights")
  END

  RETURN .ActiveUser~new(userID, username, name, surname, accessRights)

::METHOD passwordCorrect PUBLIC
  EXPOSE conn
  USE ARG username, password
  query = "SELECT Password, Salt FROM user WHERE Username = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, username)
  queryResults = prepStatement~executeQuery
  IF \queryResults~next THEN DO
    RETURN .false
  END
 
  saltHex = queryResults~getString("Salt")
  passwordHashStored = queryResults~getString("Password")
  pwh = .PasswordHasher~new
  salt = pwh~hexStringToByteArray(saltHex)
  passwordHash = pwh~generatePasswordHash(password, salt)

  RETURN passwordHash == passwordHashStored

::METHOD usernameExists PUBLIC
  EXPOSE conn
  USE ARG username
  query = "SELECT UserID FROM user WHERE Username = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, username)
  queryResults = prepStatement~executeQuery
  IF \queryResults~next THEN DO
    RETURN .false
  END
  RETURN .true

::METHOD tableExists PUBLIC
  EXPOSE conn
  USE ARG tableName, schema
  stmt = conn~createStatement
  meta = conn~getMetaData
  tables = meta~getTables(schema, .nil, tableName, .nil)
  IF tables~next THEN DO
    RETURN .true
  END
  RETURN .false

::METHOD databaseExists PUBLIC
  EXPOSE conn
  USE ARG DB_NAME
  queryResults = conn~getMetaData~getCatalogs
  DO WHILE queryResults~next
    dbnameResult = queryResults~getString(1)
    IF dbnameResult = DB_NAME THEN DO
      RETURN .true
    END
  END
  RETURN .false

::METHOD addUserToDB PUBLIC
  EXPOSE conn
  USE ARG username, password, name, surname, accessRights
  pwh = .PasswordHasher~new

  salt = pwh~generateRandomSalt
  /* Convert to hex string for storage in database */
  saltHexString = pwh~byteArrayToHexString(salt)
  /* hash password */
  passwordHash = pwh~generatePasswordHash(password, salt)
  query = "INSERT INTO user(Username, Password, Salt, Name, Surname, AccessRights) VALUES (?, ?, ?, ?, ?, ?)"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, username)
  prepStatement~setString(2, passwordHash)
  prepStatement~setString(3, saltHexString)
  prepStatement~setString(4, name)
  prepStatement~setString(5, surname)
  prepStatement~setInt(6, accessRights)
  prepStatement~execute

::METHOD changePassword PUBLIC
  EXPOSE conn
  USE ARG username, newPassword

  pwh = .PasswordHasher~new
  salt = pwh~generateRandomSalt
  saltHexString = pwh~byteArrayToHexString(salt)
  passwordHash = pwh~generatePasswordHash(newPassword, salt)

  query = "UPDATE user SET Password = ?, Salt = ? WHERE username = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, passwordHash)
  prepStatement~setString(2, saltHexString)
  prepStatement~setString(3, username)
  prepStatement~executeUpdate

::METHOD toggleAccountActiveState PUBLIC
  EXPOSE conn
  USE ARG id
  query = "UPDATE user SET Active = !Active WHERE UserID = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, id)
  prepStatement~executeUpdate

::METHOD accountActive PUBLIC
  EXPOSE conn
  USE ARG username
  query = "SELECT Active FROM user WHERE username = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, username)
  queryResults = prepStatement~executeQuery
  IF queryResults~next THEN DO
    active = queryResults~getString("Active")
  END
  RETURN active


::METHOD addProductToDB PUBLIC
  EXPOSE conn
  USE ARG name, price, taxRate
  taxID = self~getTaxID(taxRate)
  query = "INSERT INTO product(Name, Price, TaxID) VALUES (?, ?, ?)"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, name)
  prepStatement~setString(2, price)
  prepStatement~setString(3, taxID)
  prepStatement~execute

::METHOD getTaxRate PUBLIC
  EXPOSE conn
  USE ARG taxID
  query = "SELECT TaxRate FROM tax WHERE TaxID = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, taxID)
  queryResults = prepStatement~executeQuery
  IF queryResults~next THEN DO
    RETURN queryResults~getString("TaxRate")
  END


/* Input: taxRate in format: i.e. "20%" */
/* Returns: TaxID */
::METHOD getTaxID PUBLIC
  EXPOSE conn
  USE ARG taxRate
  taxRate = translate(taxRate, "", "%")
  taxRate = taxRate/100
  query = "SELECT TaxID FROM tax WHERE TaxRate = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, taxRate)
  queryResults = prepStatement~executeQuery
  IF queryResults~next THEN DO
    RETURN queryResults~getString("TaxID")
  END

::METHOD getTaxByProductID PUBLIC
  EXPOSE conn
  USE ARG prodID
  query = "SELECT TaxID FROM product WHERE ProductID = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, prodID)
  queryResults = prepStatement~executeQuery
  IF queryResults~next THEN DO
    taxID = queryResults~getString("TaxID")
  END
  RETURN self~getTaxRate(taxID)

::METHOD insertLastLoginDate PUBLIC
  EXPOSE conn
  USE ARG id
  query = "UPDATE user SET DateOfLastLogin = now() WHERE UserID = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, id)
  prepStatement~execute


::METHOD getOpenOrderArrayList PUBLIC
  /* If DateOfPayment is null the order is still open */
  EXPOSE conn FXCollections

  query = "SELECT OrderID, TableNumber FROM orders WHERE DateOfPayment IS NULL"
  statement = conn~createStatement
  queryResults = statement~executeQuery(query)

  orderArrayList = FXCollections~observableArrayList
  DO WHILE queryResults~next
    id = queryResults~getString("OrderID")
    tableNumber = queryResults~getString("TableNumber")
    orderArrayList~add(.Order~new(id, tableNumber))
  END
  RETURN orderArrayList

/* Runs a MySQL query and returns products in an observableArrayList */
::METHOD getProductArrayList PUBLIC
  EXPOSE conn FXCollections
  query = "SELECT * FROM product WHERE Availability = 1"
  statement = conn~createStatement
  queryResults = statement~executeQuery(query)
  
  productArrayList = FXCollections~observableArrayList
  DO WHILE queryResults~next
    id = queryResults~getString("ProductID")
    name = queryResults~getString("Name")
    price = queryResults~getString("Price")
    taxID = queryResults~getString("TaxID")
    taxRate = self~getTaxRate(taxID)
    productArrayList~add(.Product~new(id, name, price, taxRate))
  END
  RETURN productArrayList

::METHOD getUserArrayList PUBLIC
  EXPOSE conn FXCollections
  query = "SELECT UserID, Username, Name, Surname, AccessRights, DateOfLastLogin, Active FROM user"
  statement = conn~createStatement
  queryResults = statement~executeQuery(query)
  userArrayList = FXCollections~observableArrayList
  DO WHILE queryResults~next
    id = queryResults~getString("UserID")
    username = queryResults~getString("Username")
    name = queryResults~getString("Name")
    surname = queryResults~getString("Surname")
    accessRight = queryResults~getString("AccessRights")
    dateOfLastLogin = queryResults~getString("DateOfLastLogin")
    active = queryResults~getString("Active")
    IF active THEN active = "Active"
    ELSE active = "Deactivated"
    userArrayList~add(.User~new(id, username, name, surname, accessRight, dateOfLastLogin, active))
  END
  RETURN userArrayList

::METHOD addOrderToDB PUBLIC
  EXPOSE conn
  USE ARG tableNumber
  query = "INSERT INTO orders(UserID, TableNumber) VALUES (?, ?)"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, .my.app~activeUser~id)
  prepStatement~setString(2, tableNumber)
  prepStatement~execute

  -- Get ID of last inserted order
  query = "SELECT LAST_INSERT_ID()"
  statement = conn~createStatement
  queryResults = statement~executeQuery(query)
  queryResults~next
  lastInsertedID = queryResults~getString("LAST_INSERT_ID()")
  RETURN lastInsertedID

::METHOD addOrderDetailsToDB PUBLIC
  EXPOSE conn
  USE ARG orderID, productID, status
  query = "INSERT INTO orderContains(OrderID, ProductID, Status) VALUES (?, ?, ?)"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, orderID)
  prepStatement~setString(2, productID)
  prepStatement~setString(3, status)
  prepStatement~execute

::METHOD setOrderDetailsById PUBLIC
  EXPOSE conn FXCollections
  USE ARG id, orderDetailsHandler, paymentTable
  orderDetailsHandler~orderArrayList = FXCollections~observableArrayList

  query = "SELECT product.ProductID, product.Name, product.Price, orderContains.TempID, orderContains.Status FROM orderContains INNER JOIN product ON product.ProductID = orderContains.ProductID WHERE OrderID = ?"
  
  IF \paymentTable THEN DO
    query = query "GROUP BY ProductID"
  END
  
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, id)
  queryResults = prepStatement~executeQuery
  DO WHILE queryResults~next
    productID = queryResults~getString("ProductID")
    productName = queryResults~getString("Name")
    productPrice = queryResults~getString("Price")
    tempID = queryResults~getString("TempID")
    status = queryResults~getString("Status")
    If paymentTable THEN DO
      orderDetailsHandler~addItem(.OrderDetails~new(productID, productName, productPrice, 1, status, tempID))
    END
    ELSE DO
      countQuery = "SELECT COUNT(ProductID) AS Count FROM orderContains WHERE OrderID = ? AND ProductID = ?"
      prepStatement = conn~prepareStatement(countQuery)
      prepStatement~setString(1, id)
      prepStatement~setString(2, productID)
      queryResultCount = prepStatement~executeQuery
      IF queryResultCount~next THEN DO
        quantity = queryResultCount~getString("Count")
      END
      orderDetailsHandler~addItem(.OrderDetails~new(productID, productName, productPrice, quantity, status))
    END
  END

::METHOD removeOrderDetailsFromDB PUBLIC
  EXPOSE conn
  USE ARG id, status=.nil
  IF status = .nil THEN DO
    query = "DELETE FROM orderContains WHERE OrderID = ?"
    prepStatement = conn~prepareStatement(query)
    prepStatement~setString(1, id)
  END
  ELSE DO
    query = "DELETE FROM orderContains WHERE OrderID = ? AND Status = ?"
    prepStatement = conn~prepareStatement(query)
    prepStatement~setString(1, id)
    prepStatement~setString(2, status)
  END
  prepStatement~execute

::METHOD setStatusInDB PUBLIC
  EXPOSE conn
  USE ARG status, tempID
  query = "UPDATE orderContains SET Status = ? WHERE TempID = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, status)
  prepStatement~setString(2, tempID)
  prepStatement~executeUpdate

::METHOD insertDateOfPayment PUBLIC
  EXPOSE conn
  USE ARG orderID
  query = "UPDATE orders SET DateOfPayment = NOW() WHERE OrderID = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, orderID)
  prepStatement~executeUpdate

  query = "SELECT DateOfPayment FROM orders WHERE OrderID = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, orderID)
  queryResults = prepStatement~executeQuery
  IF queryResults~next THEN DO
    date = queryResults~getString("DateOfPayment")
  END
  RETURN date

::METHOD orderEmpty PUBLIC
  EXPOSE conn
  USE ARG orderID
  query = "SELECT * FROM orderContains WHERE orderID = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, orderID)
  queryResults = prepStatement~executeQuery
  IF \queryResults~next THEN DO 
    RETURN .true
  END
  RETURN .false

::METHOD removeOrderFromDB PUBLIC
  EXPOSE conn
  USE ARG orderID
  query = "DELETE FROM orders WHERE OrderID = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, orderID)
  prepStatement~execute

::METHOD makeProductUnavailable PUBLIC
  EXPOSE conn
  USE ARG productID
  query = "UPDATE product SET Availability = 0 WHERE ProductID = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, productID)
  prepStatement~executeUpdate

::METHOD updateAccessRight PUBLIC
  EXPOSE conn
  USE ARG username, accessRight
  query = "UPDATE user SET accessRights = ? WHERE Username = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, accessRight)
  prepStatement~setString(2, username)
  prepStatement~executeUpdate


::METHOD getBusinessInformation PUBLIC
  EXPOSE conn
  bizInf = .table~new
  query = "SELECT * FROM businessInformation"
  prepStatement = conn~prepareStatement(query)
  queryResults = prepStatement~executeQuery
  IF queryResults~next THEN DO
    bizInf["Name"] = queryResults~getString("Name")
    bizInf["Postcode"] = queryResults~getString("Postcode")
    bizInf["City"] = queryResults~getString("City")
    bizInf["Address"] = queryResults~getString("Address")
    bizInf["PhoneNumber"] = queryResults~getString("PhoneNumber")
    bizInf["Email"] = queryResults~getString("Email")
    bizInf["VatID"] = queryResults~getString("VatID")
    bizInf["CashRegisterID"] = queryResults~getString("CashRegisterID")
    bizInf["CertSerialNumber"] = queryResults~getString("CertSerialNumber")
    bizInf["AES256Key"] = queryResults~getString("AES256Key")
    bizInf["PrivateKey"] = queryResults~getString("PrivateKey")
  END
  RETURN bizInf

::METHOD getTurnover PUBLIC
  EXPOSE conn
  query = 'SELECT sum(product.Price) AS sum FROM product INNER JOIN orderContains ON orderContains.ProductID = product.ProductID WHERE orderContains.Status = "Paid"'
  prepStatement = conn~prepareStatement(query)
  queryResults = prepStatement~executeQuery
  IF queryResults~next THEN DO
    turnover = queryResults~getString("sum")
  END
  RETURN turnover

::METHOD getDistinctMonths PUBLIC
  EXPOSE conn
  query = "SELECT COUNT(DISTINCT MONTH(DateOfPayment), YEAR(DateOfPayment)) as count FROM orders"
  prepStatement = conn~prepareStatement(query)
  queryResults = prepStatement~executeQuery
  IF queryResults~next THEN count = queryResults~getString("count")
  ELSE count = 0
  RETURN count

::METHOD countActiveRootUsers PUBLIC
  EXPOSE conn
  query = "SELECT count(Username) AS count FROM user WHERE AccessRights = 4 AND Active = 1"
  prepStatement = conn~prepareStatement(query)
  queryResults = prepStatement~executeQuery
  IF queryResults~next THEN DO
    count = queryResults~getString("count")
  END
  RETURN count

::METHOD getLastOrderJWS PUBLIC
  EXPOSE conn
  query = "SELECT JwsHeader, JwsPayload, JwsSignature FROM orders ORDER BY DateOfPayment desc LIMIT 2"
  prepStatement = conn~prepareStatement(query)
  queryResults = prepStatement~executeQuery
  
  DO WHILE queryResults~next
      header = queryResults~getString("JwsHeader")
    payload = queryResults~getString("JwsPayload")
    signature = queryResults~getString("JwsSignature")
  END

  IF header = .nil THEN RETURN .array~of(.nil, .nil)
  RETURN .array~of(payload, signature)


::METHOD storeJWS PUBLIC
  EXPOSE conn 
  USE ARG id, header, payload, signature
  query = "UPDATE orders SET JwsHeader = ?, JwsPayload = ?, JwsSignature = ? WHERE OrderID = ?"
  prepStatement = conn~prepareStatement(query)
  prepStatement~setString(1, header)
  prepStatement~setString(2, payload)
  prepStatement~setString(3, signature)
  prepStatement~setString(4, id)
  prepStatement~executeUpdate

::METHOD getMonthlyTurnover PUBLIC
    EXPOSE conn
    query = 'SELECT MONTH(DateOfPayment), MONTHNAME(DateOfPayment) AS month, YEAR(DateOfPayment) AS year, sum(product.Price) AS sum FROM product INNER JOIN orderContains ON orderContains.ProductID =  product.ProductID INNER JOIN orders ON orders.OrderID = orderContains.OrderID WHERE orderContains.Status = "Paid" GROUP BY YEAR(orders.DateOfPayment), MONTHNAME(orders.DateOfPayment), MONTH(orders.DateOfPayment) ORDER BY YEAR(orders.DateOfPayment), MONTH(orders.DateOfPayment)'
    prepStatement = conn~prepareStatement(query)
    queryResults = prepStatement~executeQuery
    dates = .array~new
    revenues = .array~new
    DO WHILE queryResults~next
        dates~append(queryResults~getString("month") queryResults~getString("year"))
        revenues~append(queryResults~getString("sum"))
    END
    monthlyTurnover = .table~new
    monthlyTurnover['dates'] = dates
    monthlyTurnover['revenues'] = revenues
    RETURN monthlyTurnover



::REQUIRES "BSF.CLS"
::REQUIRES "ActiveUser.CLS"
::REQUIRES "PasswordHasher.CLS"
::REQUIRES "TableHandler.CLS"