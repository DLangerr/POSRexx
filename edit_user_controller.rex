/*@get(userTable idCol usernameCol nameCol surnameCol accessRightCol dateOfLastLoginCol activeCol)*/

userArrayList = .my.app~dbh~getUserArrayList 
.my.app~userHandler = .UserHandler~new(userArrayList, userTable, idCol, usernameCol, nameCol, surnameCol, accessRightCol, dateOfLastLoginCol, activeCol)


::ROUTINE editAccessRight PUBLIC
  /*@get(userTable)*/
  item = userTable~getSelectionModel~getSelectedItem
  IF \itemSelected(userTable) THEN .my.app~stageHandler~showDialog("WARNING", "WARNING", "No entry selected")
  ELSE DO
    user = BsfRexxProxy(item)
    .my.app~selectedUsername = user~username~get
    accessRight = user~accessRight~get
    active = user~active~get
    IF accessRight = 4 & .my.app~dbh~countActiveRootUsers() <= 1 & active = "Active" THEN DO
      .my.app~stageHandler~showDialog("ERROR", "ERROR", "Cannot remove/reduce rights of last active root user.")
    END
    ELSE DO
      .my.app~stageHandler~newWindow("Access right change", "file:change_access_right.fxml")
    END
  END

::ROUTINE overwritePassword PUBLIC
  /*@get(userTable)*/
  item = userTable~getSelectionModel~getSelectedItem
  IF \itemSelected(userTable) THEN .my.app~stageHandler~showDialog("WARNING", "WARNING", "No entry selected")
  ELSE DO
    user = BsfRexxProxy(item)
    .my.app~selectedUsername = user~username~get
    .my.app~resetPassword = .true
    .my.app~stageHandler~newWindow("Password change", "file:change_password.fxml")
  END

::ROUTINE changeActiveState PUBLIC
  /*@get(userTable)*/
  item = userTable~getSelectionModel~getSelectedItem
  IF \itemSelected(userTable) THEN .my.app~stageHandler~showDialog("WARNING", "WARNING", "No entry selected")
  ELSE DO
    user = BsfRexxProxy(item)
    id = user~id~get
    accessRight = user~accessRight~get
    active = user~active~get
    SIGNAL ON ANY NAME updateError
    IF accessRight = 4 & .my.app~dbh~countActiveRootUsers <= 1 & active = "Active" THEN DO
      .my.app~stageHandler~showDialog("error", "Error", "Cannot disable last active root user")
    END
    ELSE DO
      .my.app~dbh~toggleAccountActiveState(id)
    END
    SIGNAL OFF ANY
    userArrayList = .my.app~dbh~getUserArrayList
    .my.app~userHandler~updateArrayList(userArrayList)
  END
  EXIT 0 

updateError:
  .my.app~stageHandler~showDialog("error", "Datebase error", "Database error")
  RETURN 

::REQUIRES "BSF.CLS"
::REQUIRES "controller.rex"
::REQUIRES "functions.rex"
