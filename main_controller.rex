/*@get(anchorPane orderTable orderIDCol tableNumberCol orderDetailsTable orderProdIDCol orderProdNameCol orderProdPriceCol orderProdQuantityCol orderStatusCol orderText)*/
/*@get(showStatsButton addProductButton addUserButton newOrderButton editOrderButton splitPayButton fullPayButton editUserButton editBizInfButton)*/
FXCollections = bsf.import("javafx.collections.FXCollections")

.my.app~orderText = orderText
orderArrayList = .my.app~dbh~getOpenOrderArrayList()
.my.app~orderHandler = .OrderHandler~new(orderArrayList, orderTable, orderIDCol, tableNumberCol)
orderDetailsArrayList = FXCollections~observableArrayList
.my.app~orderDetailsHandler = .OrderDetailsHandler~new(orderDetailsArrayList, orderDetailsTable, orderProdIDCol, orderProdNameCol, orderProdPriceCol, orderProdQuantityCol, orderStatusCol)

accessRight = .my.app~activeUser~accessRights

tierTwoButtons = .array~of(addProductButton, newOrderButton, editOrderButton, splitPayButton, fullPayButton)
tierThreeButtons = .array~of(addUserButton, showStatsButton)
tierFourButtons = .array~of(editUserButton, editBizInfButton) 

IF accessRight < 4 THEN DO
  DO button OVER tierFourButtons
    button~disable = .true
  END
  IF accessRight < 3 THEN DO
    DO button OVER tierThreeButtons
    button~disable = .true
    END
    IF accessRight < 2 THEN DO
      DO button OVER tierTwoButtons
        button~disable = .true
      END
    END
  END
END

::ROUTINE openStats PUBLIC
  IF .my.app~dbh~getDistinctMonths = 0 THEN DO
    .my.app~stageHandler~showDialog("ERROR", "No data error", "No data found. Check again after completing orders")
    RETURN
  END
  .my.app~stageHandler~newWindow("Statistics", "file:barChart.fxml")

::ROUTINE startFullPayment PUBLIC
  /*@get(orderDetailsTable orderTable)*/
  CALL startPayment orderDetailsTable, orderTable, .false

::ROUTINE startSplitPayment PUBLIC
  /*@get(orderDetailsTable orderTable)*/
  CALL startPayment orderDetailsTable, orderTable

::ROUTINE openPasswordChangeWindow PUBLIC
  .my.app~resetPassword = .false
  .my.app~stageHandler~newWindow("Password change", "file:change_password.fxml")

::ROUTINE openBizInfWindow PUBLIC
  .my.app~stageHandler~newWindow("Change business informations", "file:edit_business_information.fxml")

::ROUTINE openUserForm PUBLIC
  .my.app~addRoot = .false 
  .my.app~stageHandler~loadScene("Add User", "file:add_user.fxml")

::ROUTINE editOrder PUBLIC
  IF .my.app~currentOrderID = .nil THEN DO
    .my.app~stageHandler~showDialog("WARNING", "WARNING", "Please choose an order")
  END
  ELSE DO
    .my.app~stageHandler~loadScene("Add Order", "file:add_order.fxml")
  END

::ROUTINE reprintLastReceipt PUBLIC
  rec = .my.app~lastReceipt
  IF rec = .nil THEN .my.app~stageHandler~showDialog("ERROR", "ERROR", "No receipt printed in current session")
  ELSE DO
    CALL printReceipt rec
  END
::ROUTINE openProductForm PUBLIC
  .my.app~stageHandler~loadScene("Add Product", "file:add_product.fxml")


::ROUTINE newOrder PUBLIC
  .my.app~currentOrderID = .nil
  .my.app~stageHandler~loadScene("Add Order", "file:add_order.fxml")

::ROUTINE editUserScene PUBLIC
  .my.app~stageHandler~loadScene("Edit users", "file:edit_user.fxml")



::REQUIRES "BSF.CLS"
::REQUIRES "functions.rex"
::REQUIRES "TableHandler.CLS"
