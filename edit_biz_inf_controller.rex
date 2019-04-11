/*@get(defaultButton nameTF postcodeTF cityTF addressTF numberTF emailTF vatIdTF cashRegTF certSerialTF aes256TF privKeyTF)*/
IF .my.app~dbh~bizInfExists THEN DO
  bizInf = .my.app~dbh~getBusinessInformation
  nameTF~text = bizInf['Name']
  postcodeTF~text = bizInf['Postcode']
  cityTF~text = bizInf['City']
  addressTF~text = bizInf['Address']
  numberTF~text = bizInf['PhoneNumber']
  emailTF~text = bizInf['Email']
  vatIdTF~text = bizInf['VatID']
  cashRegTF~text = bizInf['CashRegisterID']
  certSerialTF~text = bizInf['CertSerialNumber']
  aes256TF~text = bizInf['AES256Key']
  privKeyTF~text = bizInf['PrivateKey']
  defaultButton~disable = .true
  defaultButton~opacity = 0
END

::ROUTINE fillDefault PUBLIC
  /*@get(nameTF postcodeTF cityTF addressTF numberTF emailTF vatIdTF cashRegTF certSerialTF aes256TF privKeyTF)*/
  nameTF~text = "Test Company"
  postcodeTF~text = "1000"
  cityTF~text = "Vienna"
  addressTF~text = "Companystreet 10"
  numberTF~text = "+43 1000 000"
  emailTF~text = "company@email.com"
  vatIdTF~text = "ATU1000000"
  cashRegTF~text = "REGISTRIERKASSE1"
  certSerialTF~text = "21483750523945"
  aes256TF~text = "bNAnv0+/MtGMBfYJGhLv70wWtg431Df1iMX923D7tt0="
  privKeyTF~text = "MEECAQAwEwYHKoZIzj0CAQYIKoZIzj0DAQcEJzAlAgEBBCBcRhqsftzHbOkX/DmxI1gUUBi/YwVOo2Cg/rp5rBv//w=="


::ROUTINE submitChange PUBLIC
  USE ARG slotDir
  /*@get(nameTF postcodeTF cityTF addressTF numberTF emailTF vatIdTF cashRegTF certSerialTF aes256TF privKeyTF)*/
  name = nameTF~text
  postcode = postcodeTF~text
  city = cityTF~text
  address = addressTF~text
  number = numberTF~text
  email = emailTF~text
  vatID = vatIdTF~text
  cashReg = cashRegTF~text
  certSerial = certSerialTF~text
  aes256 = aes256TF~text
  priv = privKeyTF~text

  IF name~strip = "" | postcode~strip = "" | city~strip = "" | address~strip = "" | number~strip = "" | email~strip = "" | vatID~strip = "" | cashReg~strip = "" | certSerial~strip = "" | aes256~strip = "" | priv~strip = "" THEN DO
    .my.app~stageHandler~showDialog("ERROR", "Form error", "Please fill in all inputs")
    EXIT 0
  END
  IF DATATYPE(certSerial~strip) <> "NUM" THEN CALL badValue
  ELSE IF certSerial~strip~length > 18 THEN CALL sizeError

  IF .my.app~dbh~bizInfExists THEN .my.app~dbh~removeBizInf -- Remove old business informations
  SIGNAL ON ANY NAME insertError
  .my.app~dbh~addBusinessInformation(name, postcode, city, address, number, email, vatID, cashReg, certSerial, aes256, priv)
  SIGNAL OFF ANY
  .my.app~stageHandler~windowStage~close
  IF \.my.app~dbh~rootUserExists THEN DO -- No root user found, Load root user account creation
      .my.app~addRoot = .true  -- Next user added is going to have root access
      .my.app~stageHandler~loadScene("Add Root User", "file:add_user.fxml")
    END
  EXIT

insertError:
  .my.app~stageHandler~showDialog("ERROR", "Form error", "Please verify inputs.")
  EXIT

badValue:
  .my.app~stageHandler~showDialog("ERROR", "Form error", "The certifcation serial number should be in decimal format.")
  EXIT
sizeError:
  .my.app~stageHandler~showDialog("ERROR", "Form error", "The certifcation serial number is too long.")
  EXIT

::REQUIRES "functions.rex"
::REQUIRES "BSF.CLS"