/* Class PropertyValueFactory taken out of sample fxml_99 by Prof. Rony G. Flatscher under Apache Version 2.0 license */
/* Handler Classes are using PersonOverviewController Class out of sample fxml_99 by Prof. Rony. G. Flatscher as a reference under Apache Version 2.0 license */

 /*
      --------------------- Apache Version 2.0 license ----------------------
         Copyright 2016-2017 Rony G. Flatscher

         Licensed under the Apache License, Version 2.0 (the "License");
         you may not use this file except in compliance with the License.
         You may obtain a copy of the License at

             http://www.apache.org/licenses/LICENSE-2.0

         Unless required by applicable law or agreed to in writing, software
         distributed under the License is distributed on an "AS IS" BASIS,
         WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
         See the License for the specific language governing permissions and
         limitations under the License.
      --------------------------------------------------------
*/



/* ============================================================= */

/* implements "R javafx.util.Callback<P,R>(P o) for PropertyValueFactory */

/* This class allows instances that remember the message to be sent to person instances to
   return the property of the attribute that should be shown in the table cell.
*/

::class PropertyValueFactory PUBLIC
::method init
  expose  propName   --handler -- name of property getter method
  use strict arg propName -- , handler

::method call
  expose propName   -- handler
  use arg o          -- an observable value for the ooRexx person object boxed in a Java RexxProxy object
  return BsfRexxProxy(o~getValue)~send(propName)

::CLASS Order PUBLIC
::METHOD id ATTRIBUTE 
::METHOD tableNumber ATTRIBUTE
::METHOD INIT
  EXPOSE id tableNumber
  USE ARG idArg, tableNumberArg
  SimpleStringProperty = bsf.import("javafx.beans.property.SimpleStringProperty")
  id = SimpleStringProperty~new(idArg)
  tableNumber = SimpleStringProperty~new(tableNumberArg)

::CLASS OrderHandler PUBLIC
::METHOD INIT
  EXPOSE orderArrayList table idColumn tableColumn
  USE ARG orderArrayList, table, idColumn, tableColumn

  listener = BsfCreateRexxProxy(self,,"javafx.event.EventHandler")
  table~setOnMouseClicked(listener)
  --table~getSelectionModel~selectedItemProperty~addListener(listener)
  table~setColumnResizePolicy(table~CONSTRAINED_RESIZE_POLICY)

  idColumn~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("id"), ,"javafx.util.Callback"))
  tableColumn~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("tableNumber"), ,"javafx.util.Callback"))
  self~setItems

::METHOD setItems 
  EXPOSE table orderArrayList
  table~setItems(orderArrayList)

::METHOD handle
  USE ARG event
  table = event~getSource
  IF table~getSelectionModel~getSelectedItem <> .nil THEN DO
    order = table~getSelectionModel~getSelectedItem
    /* Convert Rexx proxy back to order instance */
    order = BsfRexxProxy(order)
    FXCollections = bsf.import("javafx.collections.FXCollections")
    .my.app~orderDetailsHandler~orderArrayList = FXCollections~observableArrayList

    .my.app~dbh~setOrderDetailsById(order~id~get, .my.app~orderDetailsHandler, .true)
    .my.app~orderText~text = "Order:" order~id~get
    .my.app~currentOrderID = order~id~get
    .my.app~tableNumber = order~tableNumber~get
  END

::METHOD orderArrayList ATTRIBUTE
::METHOD table ATTRIBUTE
::METHOD idColumn ATTRIBUTE
::METHOD tableColumn ATTRIBUTE

::CLASS OrderDetails PUBLIC
::METHOD tempID ATTRIBUTE
::METHOD productID ATTRIBUTE
::METHOD productName ATTRIBUTE
::METHOD productPrice ATTRIBUTE
::METHOD quantity ATTRIBUTE
::METHOD status ATTRIBUTE
::METHOD INIT
  EXPOSE productID productName productPrice quantity status tempID
  USE ARG productIDArg, productNameArg, productPriceArg, quantityArg, statusArg, tempID=1
  
  SimpleStringProperty = bsf.import("javafx.beans.property.SimpleStringProperty")
  SimpleIntegerProperty = bsf.import("javafx.beans.property.SimpleIntegerProperty")
  SimpleFloatProperty = bsf.import("javafx.beans.property.SimpleFloatProperty")

  productID = SimpleStringProperty~new(productIDArg)
  productName = SimpleStringProperty~new(productNameArg)
  productPrice = SimpleFloatProperty~new(productPriceArg)
  quantity = SimpleIntegerProperty~new(quantityArg)
  status = SimpleStringProperty~new(statusArg)

::CLASS OrderDetailsHandler PUBLIC
::METHOD INIT
  EXPOSE orderArrayList table idColumn nameCol priceCol quantityCol statusCol statusMessage paymentTable 
  USE ARG orderArrayList, table, idColumn, nameCol, priceCol, quantityCol, statusCol, paymentTable=.true

  statusMessage = .array~new
  statusMessage[1] = "Not paid"
  statusMessage[2] = "Pending"
  statusMessage[3] = "Paid"

  listener = BsfCreateRexxProxy(self,,"javafx.event.EventHandler")
  table~setOnMouseClicked(listener)
  --table~getSelectionModel~selectedItemProperty~addListener(listener)
  table~setColumnResizePolicy(table~CONSTRAINED_RESIZE_POLICY)
  idColumn~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("productID"), ,"javafx.util.Callback"))
  nameCol~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("productName"), ,"javafx.util.Callback"))
  priceCol~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("productPrice"), ,"javafx.util.Callback"))
  IF paymentTable THEN DO
      statusCol~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("status"), ,"javafx.util.Callback"))
    END
    ELSE DO
      quantityCol~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("quantity"), ,"javafx.util.Callback"))
    END

  self~setItems

::METHOD orderArrayList ATTRIBUTE
::METHOD table ATTRIBUTE
::METHOD idColumn ATTRIBUTE
::METHOD nameCol ATTRIBUTE
::METHOD priceCol ATTRIBUTE
::METHOD quantityCol ATTRIBUTE
::METHOD paymentTable ATTRIBUTE
::METHOD statusMessage ATTRIBUTE
::METHOD setItems 
  EXPOSE table orderArrayList
  table~setItems(orderArrayList)
::METHOD addItem
  EXPOSE table orderArrayList
  USE ARG item
  orderArrayList~add(item)
  self~setItems

::METHOD handle
  EXPOSE statusMessage paymentTable
  USE ARG event
  table = event~getSource
  order = table~getSelectionModel~getSelectedItem

  IF order <> .nil THEN DO
    -- Convert Rexx proxy back to order instance 
    orderInstance = BsfRexxProxy(order)
    tempID = orderInstance~tempID
    productID = orderInstance~productID~get
    productName = orderInstance~productName~get
    productPrice = orderInstance~productPrice~get
    quantity = orderInstance~quantity~get
    status = orderInstance~status~get
    IF paymentTable THEN DO
      IF status = statusMessage[2] THEN DO
        orderInstance~status~set(statusMessage[1])
        .my.app~dbh~setStatusInDB(statusMessage[1], tempID) -- Update changes to DB
      END
      ELSE IF status = statusMessage[1] THEN DO
        orderInstance~status~set(statusMessage[2])
        .my.app~dbh~setStatusInDB(statusMessage[2], tempID) 
      END
    END
    ELSE DO -- Not paymentTable
      IF quantity > 1 THEN DO
        orderInstance~quantity~set(quantity-1)
      END
      ELSE DO
        table~getItems~remove(order)
      END
    END
  END

::CLASS Product PUBLIC
::METHOD id ATTRIBUTE
::METHOD name ATTRIBUTE
::METHOD price ATTRIBUTE
::METHOD tax ATTRIBUTE
::METHOD INIT
  EXPOSE id name price tax
  USE ARG idArg, nameArg, priceArg, taxArg

  SimpleStringProperty = bsf.import("javafx.beans.property.SimpleStringProperty")

  id = SimpleStringProperty~new(idArg)
  name = SimpleStringProperty~new(nameArg)
  price = SimpleStringProperty~new(priceArg)
  tax = SimpleStringProperty~new(taxArg)


::CLASS ProductHandler PUBLIC
::METHOD INIT 
  EXPOSE productArrayList table idColumn nameColumn priceColumn taxColumn
  USE ARG productArrayList, table, idColumn, nameColumn, priceColumn, taxColumn

  listener = BsfCreateRexxProxy(self,,"javafx.event.EventHandler")
  table~setOnMouseClicked(listener)
  --table~getSelectionModel~selectedItemProperty~addListener(listener)

  idColumn~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("id"), ,"javafx.util.Callback"))
  nameColumn~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("name"), ,"javafx.util.Callback"))
  priceColumn~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("price"), ,"javafx.util.Callback"))
  taxColumn~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("tax"), ,"javafx.util.Callback"))
  table~setColumnResizePolicy(table~CONSTRAINED_RESIZE_POLICY)

  self~setItems

::METHOD productArrayList ATTRIBUTE
::METHOD table ATTRIBUTE
::METHOD idColumn ATTRIBUTE
::METHOD nameColumn ATTRIBUTE
::METHOD priceColumn ATTRIBUTE
::METHOD taxColumn ATTRIBUTE
::METHOD setItems 
  EXPOSE table productArrayList
  table~setItems(productArrayList)

::METHOD handle
  USE ARG event
  table = event~getSource
  IF table~getSelectionModel~getSelectedItem <> .nil THEN DO
    product = table~getSelectionModel~getSelectedItem
    /* Convert Rexx proxy back to product instance */
    product = BsfRexxProxy(product)
    orderDetails = .OrderDetails~new(product~id~get, product~name~get, product~price~get, 1, "Not paid")
    item = findProductInOrder(orderDetails)
    IF item = .nil THEN DO
      CALL addOrderDetails orderDetails
    END
    ELSE DO
      CALL incrementQuantity item
    END
  END


::CLASS User PUBLIC
::METHOD id ATTRIBUTE
::METHOD username ATTRIBUTE
::METHOD name ATTRIBUTE
::METHOD surname ATTRIBUTE
::METHOD accessRight ATTRIBUTE
::METHOD dateOfLastLogin ATTRIBUTE
::METHOD active ATTRIBUTE
::METHOD INIT
  EXPOSE id username name surname accessRight dateOfLastLogin active
  USE ARG idArg, usernameArg, nameArg, surnameArg, accessRightArg, dateOfLastLoginArg, activeArg

  SimpleStringProperty = bsf.import("javafx.beans.property.SimpleStringProperty")
  
  id = SimpleStringProperty~new(idArg)
  username = SimpleStringProperty~new(usernameArg)
  name = SimpleStringProperty~new(nameArg)
  surname = SimpleStringProperty~new(surnameArg)
  accessRight = SimpleStringProperty~new(accessRightArg)
  dateOfLastLogin = SimpleStringProperty~new(dateOfLastLoginArg)
  active = SimpleStringProperty~new(activeArg)


::CLASS UserHandler PUBLIC
::METHOD INIT 
  EXPOSE userArrayList table idCol usernameCol nameCol surnameCol accessRightCol dateOfLastLoginCol activeCol
  USE ARG userArrayList, table, idCol, usernameCol, nameCol, surnameCol, accessRightCol, dateOfLastLoginCol, activeCol

  idCol~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("id"), ,"javafx.util.Callback"))
  usernameCol~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("username"), ,"javafx.util.Callback"))
  nameCol~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("name"), ,"javafx.util.Callback"))
  surnameCol~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("surname"), ,"javafx.util.Callback"))
  accessRightCol~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("accessRight"), ,"javafx.util.Callback"))
  dateOfLastLoginCol~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("dateOfLastLogin"), ,"javafx.util.Callback"))
  activeCol~setCellValueFactory(BsfCreateRexxProxy(.PropertyValueFactory~new("active"), ,"javafx.util.Callback"))

  table~setColumnResizePolicy(table~CONSTRAINED_RESIZE_POLICY)

  self~setItems

::METHOD userArrayList ATTRIBUTE
::METHOD table ATTRIBUTE
::METHOD idCol ATTRIBUTE
::METHOD usernameCol ATTRIBUTE
::METHOD nameCol ATTRIBUTE
::METHOD surnameCol ATTRIBUTE
::METHOD accessRightCol ATTRIBUTE
::METHOD dateOfLastLoginCol ATTRIBUTE
::METHOD activeCol ATTRIBUTE
::METHOD setItems 
  EXPOSE table userArrayList
  table~setItems(userArrayList)
::METHOD updateArrayList
  EXPOSE userArrayList
  USE ARG userArrayList
  self~setItems

::REQUIRES "BSF.CLS"
::REQUIRES "functions.rex"