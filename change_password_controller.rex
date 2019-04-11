/*@get(oldPassword)*/

IF .my.app~resetPassword THEN oldPassword~disable=.true

::ROUTINE submitPasswordChange PUBLIC
  /*@get(oldPassword newPassword newPasswordRepeat)*/
  IF newPassword~text <> newPasswordRepeat~text THEN DO
    .my.app~stageHandler~showDialog("ERROR", "ERROR", "New password does not match")
  END
  ELSE IF newPassword~text = oldPassword~text THEN DO
    .my.app~stageHandler~showDialog("ERROR", "ERROR", "New password matches old password")
  END
  ELSE IF \oldPassword~disable & \.my.app~dbh~passwordCorrect(.my.app~activeUser~username, oldPassword~text) THEN DO
    .my.app~stageHandler~showDialog("ERROR", "ERROR", "Incorrect password")
  END
  ELSE DO
    SIGNAL ON ANY NAME databaseError
    IF .my.app~resetPassword THEN DO -- Changing password of a different user
      .my.app~dbh~changePassword(.my.app~selectedUsername, newPassword~text)
    END
    ELSE DO -- Changing own password
      .my.app~dbh~changePassword(.my.app~activeUser~username, newPassword~text)
    END
    SIGNAL OFF ANY
    .my.app~stageHandler~showDialog("INFO", "Success message", "Password successfully changed.")
    .my.app~stageHandler~windowStage~close
  END

  EXIT 0

databaseError:
  .my.app~stageHandler~showDialog("ERROR", "Database error", "Database error on password change")
  RETURN

::REQUIRES "controller.rex"
::REQUIRES "functions.rex"
::REQUIRES "BSF.CLS"