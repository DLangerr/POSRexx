/* All functions and routines */

::ROUTINE startPayment PUBLIC
  USE ARG orderDetailsTable, orderTable, splitPayment = .true
  pendingcount = countPending(orderDetailsTable)
  IF pendingCount = 2 THEN splitPayment = .false  -- All remaining items are getting paid next

  IF orderDetailsTable~getItems~isEmpty THEN DO
    .my.app~stageHandler~showDialog("WARNING", "WARNING", "Please choose an order")
    EXIT 
  END
  ELSE IF pendingCount = 0 & splitPayment THEN DO
    .my.app~stageHandler~showDialog("WARNING", "WARNING", "Please select products")
    EXIT 
  END

  /* Get business informations for receipt */
  receipt = .my.app~dbh~getBusinessInformation

  NUMERIC DIGITS 20
  hexSerialNr =  D2X(receipt["CertSerialNumber"])
  NUMERIC DIGITS 


  jwsHandler = .JWSHandler~new
  SIGNAL ON ANY NAME privateKeyError
  privateKey = jwsHandler~privateKeyFromString(receipt['PrivateKey'])
  jwsHandler~encryptECDSA("Test", privateKey)
  SIGNAL OFF ANY
  
  turnoverT = .table~new
  turnoverT["20"] = .array~new  -- Products with  20% tax
  turnoverT["10"] = .array~new    -----------   19% tax
  turnoverT["13"] = .array~new  ------------  13% tax
  turnoverT["0"] = .array~new   ------------  10% tax
  turnoverT["19"] = .array~new    ------------  0% tax

  products = .array~new
  productCount = .array~new
  prices = .array~new
  IF splitPayment THEN DO
    id = .my.app~dbh~addOrderToDB(.my.app~tableNumber)
  END
  ELSE id = .my.app~currentOrderID

  DO item OVER orderDetailsTable~getItems
    IF item~status~get = .my.app~orderDetailsHandler~statusMessage[2] & splitPayment | \splitPayment THEN DO
      IF splitPayment THEN DO 
        .my.app~dbh~addOrderDetailsToDB(id, item~productID~get, .my.app~orderDetailsHandler~statusMessage[3])
        .my.app~dbh~removeOrderDetailsFromDB(.my.app~currentOrderID, .my.app~orderDetailsHandler~statusMessage[2])
        .my.app~dbh~setOrderDetailsById(.my.app~currentOrderID, .my.app~orderDetailsHandler, .true)
      END
      ELSE DO
        .my.app~dbh~setStatusInDB(.my.app~orderDetailsHandler~statusMessage[3], item~tempID)
      END
      tax = .my.app~dbh~getTaxByProductID(item~productID~get)
      price = item~productPrice~get

      /* Count product frequency */
      name = item~productName~get
      IF products~hasItem(name) THEN DO
        productCount[products~index(name)] += 1
      END
      ELSE DO
        products~append(name)
        productCount~append(1)
        prices~append(price)
      END

      /* Sort products by tax brackets */   
      SELECT
        WHEN tax = 0.2 THEN turnoverT["20"]~append(price)
        WHEN tax = 0.19 THEN turnoverT["19"]~append(price)
        WHEN tax = 0.13 THEN turnoverT["13"]~append(price)
        WHEN tax = 0.1 THEN turnoverT["10"]~append(price)
        WHEN tax = 0 THEN turnoverT["0"]~append(price)
        OTHERWISE -- PASS
      END
      orderDetailsTable~getItems~remove(item)
    END
  END
  IF .my.app~dbh~orderEmpty(.my.app~currentOrderID) & splitPayment THEN DO
    .my.app~dbh~removeOrderFromDB(.my.app~currentOrderID)
    .my.app~orderHandler~orderArrayList = getOpenOrderArrayList()
    .my.app~orderHandler~setItems
  END
  IF splitPayment THEN DO
    IF .my.app~dbh~orderEmpty(.my.app~currentOrderID) THEN DO
      .my.app~dbh~removeOrderFromDB(.my.app~currentOrderID)
      .my.app~orderHandler~orderArrayList = getOpenOrderArrayList()
      .my.app~orderHandler~setItems
      orderDetailsTable~getItems~clear
    END
  END 
  ELSE DO 
    orderDetailsTable~getItems~clear
    orderTable~getItems~remove(orderTable~getSelectionModel~getSelectedItem)
  END
  date = .my.app~dbh~insertDateOfPayment(id)

    /* Create itemStringArray for later use on receipt */
  itemStringArray = .array~new
  DO i=1 TO products~items  
    itemStringArray~append(.array~of(productCount[i] products[i], format(prices[i],,2), format(prices[i]*productCount[i],,2)))
  END

  receipt['Items'] = itemStringArray
  datetime = CHANGESTR(" ", date, "T") -- Reformat date
  
  sumTable = .table~new
  formattedSumTable = .table~new

  sum = 0
  DO key OVER turnoverT
    singleSum = sum(turnoverT[key])
    sumTable[key] = singleSum
    formattedSumTable[key] = reformatFloat(singleSum)
    sum += singleSum
  END

  receipt['OrderID'] = id
  receipt['Datetime'] = datetime
  receipt['TableNumber'] = .my.app~tableNumber
  receipt['Sum'] = sum
  receipt['SumTable'] = sumTable
  receipt['UserName'] = .my.app~activeUser~name
  receipt['UserSurname'] = .my.app~activeUser~surname


  

  oldJWS = .my.app~dbh~getLastOrderJWS
  payload = oldJWS[1]
  signature = oldJWS[2]
  oldQRString = jwsHandler~restoreQRString(payload, signature)
  hashLastReceipt = jwsHandler~hashLastReceipt(oldQRString)

  taxOrder = .array~of("20", "10", "13", "0", "19")
  
  /* Encrypt turnover */
  aes = .AES256~new
  turnover = .my.app~dbh~getTurnover
  say turnover
  turnover = format(turnover*100,,0)
  say turnover
  SIGNAL ON ANY NAME encryptionError
  turnoverEncoded = aes~encrypt(turnover, receipt["AES256Key"])
  say receipt["AES256Key"]
  SIGNAL OFF ANY
  say turnoverEncoded
  /* Concatenate QR - String */
  qrText = .mutableBuffer~new
  qrText~append("_R1-AT_" || receipt["CashRegisterID"] || "_" || id || "_" || datetime)
  DO i OVER taxOrder
    qrText~append("_" || formattedSumTable[i])
  END
  qrText~append("_" || turnoverEncoded || "_" || hexSerialNr || "_" || hashLastReceipt)
  
  jws = jwsHandler~encryptECDSA(qrText~string, privateKey)

  PARSE VAR jws header "." payload "." signature .


  signatureB64 = jwsHandler~recode(signature)

  qrBuffer = qrText~append("_" || signatureB64)
  qrString = qrBuffer~string

  .my.app~dbh~storeJWS(id, header, payload, signature)
  
  /* Create QR - Code */
  CALL createQRCode qrString

  .my.app~lastReceipt = receipt
  CALL printReceipt receipt
  EXIT

encryptionError:
  .my.app~stageHandler~showDialog("ERROR", "Encryption error", "Invalid AES key. Use generateKeys.rex script to generate a new key.")
  EXIT -1

privateKeyError:
  .my.app~stageHandler~showDialog("ERROR", "Encryption error", "Invalid private key. Please verify the entered private key.")
  EXIT -1

::ROUTINE createQRCode 
  USE ARG text, path="res/qr.png"
  qrWriter = .QRWriter~new
  qrWriter~write(path, text)


::ROUTINE appendSums PUBLIC
  USE ARG text, sumTable
  DO key OVER sumTable
    percentage = key || ".0%"
    value = sumTable[key]
    IF key = "0" THEN DO
      tax = format2f(value)
      sum = format2f(value)
    END
    ELSE DO
      tax = format2f(value/(key/100+1))
      sum = format2f(value-(value/(key/100+1)))
    END
    IF value > 0 THEN DO
      text~append("<tr><td>" || percentage || "</td><td>" || tax || "</td><td>" || sum || "</td><td>" || format(sumTable[key],,2) || "</td></tr>")
    END
  END
  RETURN text

::ROUTINE format2f 
  USE ARG float
  RETURN format(float,,2)

/* E.g. Input: 20.014010
    Output: 20,01 */
::ROUTINE reformatFloat
  USE ARG float
  RETURN translate(format2f(float), ",", ".") 

::ROUTINE printReceipt PUBLIC
  USE ARG receipt

    datetime = receipt['Datetime']
  /* Split date and time */
  PARSE VAR datetime date "T" time .
  /* Reformat date from YYYY-mm-dd TO dd.mm.YYYY */
  PARSE VAR date year "-" month "-" day .
  date = day || "." || month || "." || year

  /* Create mutableBuffer to store HTML string for receipt printing */
  text = .mutableBuffer~new
  text~append("<!DOCTYPE html>" -
        "<html>" -
          "<body>" -
            "<h1>" || receipt['Name'] || "</h1>" -
              "<span>" || receipt['Postcode'] receipt['City'] || "<br>" -
              || receipt["Address"] || "<br>" -
                "Tel.: "|| receipt["PhoneNumber"] || "<br>" -
                receipt["Email"] || "<br>" -
                "UId-Nr.: " || receipt["VatID"] || "<br>" -
                "Rechnung" receipt['OrderID'] || "<br>" -
                || "Tisch" receipt['TableNumber'] || "<br>" -
                || date || "<br>" -
                || time || "<br>" -
              "-----------------------------<br>" -
              "<table>")

  DO item OVER receipt['Items']
    text~append("<tr>")
    DO i OVER item
      text~append("<td>" || i || "</td>")
    END
    text~append("</tr>")
  END
  text~append("</table>")
  text~append("-----------------------------<br>" -
        "<h2>Rechnungsbetrag <br>EURO" receipt['Sum'] || " </h2>" -
        "=============================<br>" -
        "<table>" - 
        "<tr>" -
          "<th>MWST</th>"-
          "<th>NETTO</th>"-
          "<th>STEUER</th>"-
          "<th>BRUTTO</th>"-
        "</tr>")
        
  text = appendSums(text, receipt['SumTable'])

  filePath = "file:" || .my.app~homeDir || "/res/qr.png"

  text~append("</table><br>"-
        '<img src="' || filePath || '" width="100" height="100"><br>' -
        "Es bediente Sie " || left(receipt['UserName'], 1) || "." -
        receipt['UserSurname'] || "<br>" -
        "Wir freuen uns auf ein baldiges Wiedersehen <br>"-
        "</span></body></html>")
        
  /* Minimize Program so print window is visible*/
  .my.app~stageHandler~stage~getScene~getWindow~setIconified(.true)
  done = print(text~string)
  .my.app~stageHandler~stage~getScene~getWindow~setIconified(.false)
  IF done THEN DO
    SAY "Printing completed." 
  END
  ELSE DO
    .my.app~stageHandler~showDialog("ERROR", "ERROR", "Error printing receipt")
  END

::ROUTINE print
  USE ARG string

  jEditorPane = .bsf~new("javax.swing.JEditorPane")
  kit = .bsf~new("javax.swing.text.html.HTMLEditorKit")

  /* Add css to HTML */
  jEditorPane~setEditorKit(kit)

  /* Define stylesheet */
  styleSheet = kit~getStyleSheet
  styleSheet~addRule("body {font-size: 7px;}")
  styleSheet~addRule("h1 {font-size: 13px;}")
  styleSheet~addRule("h2 {font-size: 10px;}")

  doc = kit~createDefaultDocument
  jEditorPane~setDocument(doc)
  jEditorPane~setText(string)
  RETURN jEditorPane~print


/* Return sum of array */
::ROUTINE sum
  USE ARG arr
  sum = 0
  DO i OVER arr
    sum += i
  END
  RETURN sum

::ROUTINE itemSelected PUBLIC
  USE ARG table
  item = table~getSelectionModel~getSelectedItem
  IF item <> .nil THEN RETURN .true
  ELSE RETURN .false

/* Count pending payments 
Returns 2: all payments of selected order are pending
    1: atleast one pending payment but not all
    0: no pending payment 
*/
::ROUTINE countPending PUBLIC    -- Check if products for next payment are selected
  USE ARG orderDetailsTable
  pendingCount = 0
  itemCount = 0
  DO item OVER orderDetailsTable~getItems
      IF item~status~get = .my.app~orderDetailsHandler~statusMessage[2] THEN DO
        pendingCount += 1
      END
      itemCount +=1
  END
  IF pendingCount = 0 THEN RETURN 0       
  ELSE IF pendingCount = itemCount THEN RETURN 2
  ELSE RETURN 1 
  
::ROUTINE incrementQuantity PUBLIC
  USE ARG item
  SimpleIntegerProperty = bsf.import("javafx.beans.property.SimpleIntegerProperty")
  sum = item~quantity~add(SimpleIntegerProperty~new(1))
  item~quantity~set(sum~getValue)

::ROUTINE findProductInOrder PUBLIC
  USE ARG orderDetails
  DO item OVER .my.app~orderDetailsHandler~table~getItems
    IF item~productID~get == orderDetails~productID~get THEN DO
      RETURN item
    END
  END
  RETURN .nil

::ROUTINE addOrderDetails PUBLIC
  USE ARG orderDetails
  .my.app~orderDetailsHandler~addItem(orderDetails)

::ROUTINE loadFirstFXML PUBLIC
  /* Check if root user exits, if not open FXML for creating a root user */
  IF \.my.app~dbh~bizInfExists() THEN DO
    .my.app~stageHandler~newWindow("Add business informations", "file:edit_business_information.fxml")
  END
  ELSE IF \.my.app~dbh~rootUserExists THEN DO -- No root user found, Load root user account creation
    .my.app~addRoot = .true  -- Next user added is going to have root access
    .my.app~stageHandler~loadScene("Add Root User", "file:add_user.fxml")
  END
  ELSE DO --Root user exists, Load user login
    .my.app~stageHandler~loadScene("User Login", "file:user_login.fxml")
  END
  
::ROUTINE quitApp PUBLIC
  bsf.loadClass("javafx.application.Platform")~exit

::REQUIRES "BSF.CLS"
::REQUIRES "TableHandler.CLS"
::REQUIRES "PasswordHasher.CLS"
::REQUIRES "AES256.CLS"
::REQUIRES "QRWriter.CLS"
::REQUIRES "JWSHandler.CLS"