/*@get(taxChoiceBox productTable productIDCol productNameCol productPriceCol productTaxCol)*/
FXCollections = bsf.import("javafx.collections.FXCollections")
observArrList = FXCollections~observableArrayList
observArrList~add("20%")
observArrList~add("19%")
observArrList~add("13%")
observArrList~add("10%")
observArrList~add("0%")
taxChoiceBox~setItems(observArrList)

productArrayList = .my.app~dbh~getProductArrayList
productHandler = .ProductHandler~new(productArrayList, productTable, productIDCol, productNameCol, productPriceCol, productTaxCol)


::ROUTINE returnToMain PUBLIC
  .my.app~remove(prodID)
  .my.app~stageHandler~loadMainScene

::ROUTINE editProduct PUBLIC
  /*@get(productTable productName productPrice taxChoiceBox)*/

  item = productTable~getSelectionModel~getSelectedItem
  IF item == .nil THEN DO
    .my.app~stageHandler~showDialog("WARNING", "WARNING", "Please select a product")
  END
  ELSE DO
    product = BsfRexxProxy(item)
    .my.app~prodID = product~id~get
    productName~text = product~name~get
    productPrice~text = product~price~get
    taxString = trunc(product~tax~get*100) || "%" -- taxID to percentage
    taxChoiceBox~setValue(taxString)
  END


::ROUTINE deleteProduct PUBLIC
  /*@get(productTable productIDCol productNameCol productPriceCol productTaxCol)*/
  item = productTable~getSelectionModel~getSelectedItem
  IF item == .nil THEN DO
    .my.app~stageHandler~showDialog("WARNING", "Warning", "Please select a product")
  END
  ELSE DO
    product = BsfRexxProxy(item)
    SIGNAL ON ANY NAME updateError
    .my.app~dbh~makeProductUnavailable(product~id~get)
    SIGNAL OFF ANY
    productArrayList = .my.app~dbh~getProductArrayList
    productHandler = .ProductHandler~new(productArrayList, productTable, productIDCol, productNameCol, productPriceCol, productTaxCol)
  END
  EXIT 0

  updateError:
  .my.app~stageHandler~showDialog("ERROR", "MySQL Update Error", "MySQL database update error")
  RETURN

::ROUTINE submitProduct PUBLIC
  USE ARG slotDir
  /*@get(productTable productName productPrice taxChoiceBox productIDCol productNameCol productPriceCol productTaxCol)*/
  choice = taxChoiceBox~getSelectionModel~getSelectedItem
  price = translate(productPrice~text, ".", ",")
  IF productName~text = "" | price = "" | choice = .nil | datatype(price) <> "NUM" THEN DO
    .my.app~stageHandler~showDialog("error", "ERROR", "Verify input fields")
  END
  ELSE DO
    IF prodID = .nil THEN DO - New Product not edit
      SIGNAL ON ANY NAME insertError
      .my.app~dbh~addProductToDB(productName~text, price, choice)
      SIGNAL OFF ANY
    END
    ELSE DO
      SIGNAL ON ANY NAME updateError
      .my.app~dbh~makeProductUnavailable(.my.app~prodID)
      SIGNAL OFF ANY

      SIGNAL ON ANY NAME insertError
      .my.app~dbh~addProductToDB(productName~text, price, choice)
      SIGNAL OFF ANY
    END
    productArrayList = .my.app~dbh~getProductArrayList
    productHandler = .ProductHandler~new(productArrayList, productTable, productIDCol, productNameCol, productPriceCol, productTaxCol)
    productName~text = ""
    productPrice~text = ""
    taxChoiceBox~getSelectionModel~clearSelection
  END

  EXIT 0

insertError:
  .my.app~stageHandler~showDialog("ERROR", "MySQL Insert Error", "MySQL database insert error")
  RETURN

updateError:
  .my.app~stageHandler~showDialog("ERROR", "MySQL Update Error", "MySQL database update error")
  RETURN


::REQUIRES "BSF.CLS"
::REQUIRES "controller.rex"