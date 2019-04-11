/*@get(accessRightGroup rootRadioButton backToMainButton)*/
-- Disable access right choice on adding root user
-- First user created has to be root user
IF .my.app~addRoot THEN DO
  backToMainButton~visible = .false
  rootRadioButton~setSelected(.true)
  DO node OVER accessRightGroup~getToggles
    node~disable = .true
  END
END
IF .my.app~accessRight <> .nil THEN DO
  IF .my.app~accessRights < 4 THEN DO -- User who is not root cannot create a new root user
    rootAccessNode = accessRightGroup~getToggles~get(3)
    rootAccessNode~disable = .true
  END
END

::ROUTINE addUser PUBLIC
  USE ARG slotDir
  /*@get(addUserButton username password password2 name surname successText accessRightGroup backToMainButton)*/

  IF password~text <> password2~text THEN DO
    .my.app~stageHandler~showDialog("ERROR", "Form error", "Password does not match")
  END
  ELSE IF length(username~text) > 20 THEN DO
    .my.app~stageHandler~showDialog("ERROR", "Form error", "Username too long (max 20 chars)")
  END
  ELSE IF length(name~text) > 20 THEN DO
    .my.app~stageHandler~showDialog("ERROR", "Form error", "Name too long (max 20 chars)")
  END
  ELSE IF length(surname~Text) > 20 THEN DO
    .my.app~stageHandler~showDialog("ERROR", "Form error", "Surname too long (max 20 chars)")
  END
  ELSE IF username~text~strip = "" | password~text~strip = "" | name~text~strip = "" | surname~Text~strip = "" THEN DO
    .my.app~stageHandler~showDialog("ERROR", "Form error", "Please fill in all inputs")
  END
  ELSE IF accessRightGroup~getSelectedToggle = .nil THEN DO
    .my.app~stageHandler~showDialog("ERROR", "Form error", "Please choose access right")
  END
  ELSE IF .my.app~dbh~usernameExists(username~text) THEN DO
    .my.app~stageHandler~showDialog("ERROR", "Form error", "Username already exists")
  END
  ELSE DO
    accessRight = accessRightGroup~getToggles~indexOf(accessRightGroup~getSelectedToggle)+1
    SIGNAL ON ANY NAME databaseError
    .my.app~dbh~addUserToDB(username~text, password~text, name~text, surname~Text, accessRight)
    SIGNAL OFF ANY 
    addUserButton~disable = .true
    successText~visible = .true
    CALL SYSSLEEP 0.5
    IF \backToMainButton~visible THEN DO -- backToMainButton is not visible = currently adding first root user
      .my.app~stageHandler~loadScene("User Login", "file:user_login.fxml")
    END
    ELSE DO
      .my.app~stageHandler~loadMainScene
      .my.app~remove(addRoot)
    END
  END
  EXIT 0

databaseError:
  .my.app~stageHandler~showDialog("ERROR", "MySQL Insert Error", "MySQL database insert error")
  RETURN


::REQUIRES "functions.rex"
::REQUIRES "controller.rex"