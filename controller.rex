::ROUTINE submitAcessRightChanges PUBLIC
  /*@get(accessRightGroup)*/
  IF accessRightGroup~getSelectedToggle = .nil THEN DO
    .my.app~stageHandler~showDialog("ERROR", "Form error", "Please choose access right")
  END
  ELSE DO
    accessRight = accessRightGroup~getToggles~indexOf(accessRightGroup~getSelectedToggle)+1
    SIGNAL ON ANY NAME updateError
    .my.app~dbh~updateAccessRight(.my.app~selectedUsername, accessRight)
    SIGNAL OFF ANY
    .my.app~stageHandler~windowStage~close
    userArrayList = .my.app~dbh~getUserArrayList
    .my.app~userHandler~updateArrayList(userArrayList)
  END
  EXIT 0

updateError:
  .my.app~stageHandler~showDialog("ERROR", "ERROR", "Database update error")
  RETURN 

::ROUTINE returnToMain PUBLIC
  .my.app~stageHandler~loadMainScene


::ROUTINE submitDatabaseLogin PUBLIC
  USE ARG slotDir
  /* Start connecting to mysql */
  .my.app~dbh~initSettings("conf.ini")
  success = .my.app~dbh~connect
  IF success THEN DO
    CALL loadFirstFXML
  END
  ELSE DO
    .my.app~stageHandler~showDialog("ERROR", "Connection error", "Connecting to database failed." "0A"X "Try:" "0A"X "Run setup.rex" "0A"X  "Verify configurations in conf.ini" "0A"X "Make sure JConnector jar is added to classpath")
  END
  EXIT 0


::ROUTINE submitUserLogin PUBLIC
  USE ARG slotDir
  /*@get(username password successText)*/
  IF .my.app~dbh~passwordCorrect(username~text, password~text) THEN DO
    IF \.my.app~dbh~accountActive(username~text) THEN DO
      .my.app~stageHandler~showDialog("error", "ERROR", "Account deactivated. Please contact root user.")
      EXIT 0
    END
    successText~opacity = 1

    CALL SYSSLEEP 0.4
    .my.app~activeUser = .my.app~dbh~loadUserInformation(username~text)
    .my.app~dbh~insertLastLoginDate(.my.app~activeUser~id)
    SIGNAL ON ANY
    .my.app~stageHandler~loadMainScene
    SIGNAL OFF ANY
  END
  ELSE DO
    .my.app~stageHandler~showDialog("error", "ERROR", "Wrong username or password")
  END
  EXIT 0

ANY:
  SAY "[-] ERROR!" 
  SAY "[-] Make sure CLASSPATH for jfoenix-8.0.7.jar is set."
  .my.app~stageHandler~showDialog("error", "ERROR", "Error loading main page. Make sure CLASSPATH for jfoenix-8.0.7.jar is set.")
  SAY "[-] Quitting."
  CALL quitApp

::REQUIRES "BSF.CLS"
::REQUIRES "functions.rex"
::REQUIRES "TableHandler.CLS"
::REQUIRES "DatabaseHandler.CLS"



