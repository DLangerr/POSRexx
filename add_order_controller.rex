/*@get(tableSpinner productTable productIDCol productNameCol productPriceCol productTaxCol orderDetailsTable orderProdIDCol orderProdNameCol orderProdPriceCol orderProdQuantityCol orderStatusCol)*/
FXCollections = bsf.import("javafx.collections.FXCollections")
IntegerSpinnerValueFactory = bsf.import("javafx.scene.control.SpinnerValueFactory$IntegerSpinnerValueFactory")

valueFactory = IntegerSpinnerValueFactory~new(0, 50, 0, 1)
tableSpinner~setValueFactory(valueFactory)
.local~tableSpinner = tableSpinner

orderDetailsArrayList = FXCollections~observableArrayList
productArrayList = .my.app~dbh~getProductArrayList()
productHandler = .ProductHandler~new(productArrayList, productTable, productIDCol, productNameCol, productPriceCol, productTaxCol)

.my.app~orderDetailsHandler = .OrderDetailsHandler~new(orderDetailsArrayList, orderDetailsTable, orderProdIDCol, orderProdNameCol, orderProdPriceCol, orderProdQuantityCol, orderStatusCol, .false)
IF .my.app~currentOrderID <> .nil THEN DO -- Current Order not nil --> Editing existing order
  .my.app~dbh~setOrderDetailsById(.my.app~currentOrderID, .my.app~orderDetailsHandler,.false)
  .tableSpinner~getValueFactory~setValue(box("Int", .my.app~tableNumber))
END


::ROUTINE saveOrder PUBLIC
  /*@get(orderDetailsTable)*/
  IF orderDetailsTable~getItems~isEmpty THEN DO
    .my.app~stageHandler~showDialog("WARNING", "WARNING", "Order is empty")
  END
  ELSE IF .tableSpinner~getValue = 0 THEN DO
    .my.app~stageHandler~showDialog("WARNING", "WARNING", "Please choose a table")
  END
  ELSE DO
    -- Add new order and return generated ID
    IF .my.app~currentOrderID <> .nil THEN DO  -- Order already exists
      orderID = .my.app~currentOrderID
      .my.app~dbh~removeOrderDetailsFromDB(orderID) -- Remove old entries --> Then add new entries
    END
    ELSE do -- Order does not exist --> Create new order
      orderID = .my.app~dbh~addOrderToDB(.tableSpinner~getValue) -- Order does not exist --> Add new order and return generated id
    END
    DO item OVER orderDetailsTable~getItems
      DO i=1 FOR item~quantity~get
        .my.app~dbh~addOrderDetailsToDB(orderID, item~productID~get, item~status~get)
      END
    END
    .my.app~currentOrderID = .nil
    .my.app~stageHandler~loadMainScene
  END

::REQUIRES "BSF.CLS"
::REQUIRES "functions.rex"
::REQUIRES "TableHandler.CLS"
::REQUIRES "controller.rex"