PARSE SOURCE . . fullPath
CALL directory filespec('L', fullPath)

.environment~setEntry("my.app", .directory~new)
.my.app~homeDir = filespec('Location',fullPath)
.my.app~dbh = .DatabaseHandler~new
stageHandler = .StageHandler~new
.my.app~stageHandler = stageHandler
stageHandlerProxy = BsfCreateRexxProxy(stageHandler,,"javafx.application.Application")
stageHandlerProxy~launch(stageHandlerProxy~getClass, .nil)
EXIT 0

::CLASS StageHandler
::METHOD stage ATTRIBUTE
::METHOD scene ATTRIBUTE
::METHOD windowStage ATTRIBUTE
::METHOD FXMLLoader
::METHOD init
  EXPOSE FXMLLoader
  FXMLLoader = bsf.import("javafx.fxml.FXMLLoader")
::METHOD start
  EXPOSE stage scene FXMLLoader
  USE ARG stage
  /* GraphicsEnvironment to get Screen resolution */
  GraphicsEnvironment = bsf.loadClass("java.awt.GraphicsEnvironment")
  gd = GraphicsEnvironment~getLocalGraphicsEnvironment~getDefaultScreenDevice
  stage~setTitle("Database login")
  stage~getIcons~add(.bsf~new("javafx.scene.image.Image", "file:res/icon.png"))
  url=.bsf~new("java.net.URL", "file:db_login.fxml")
  fxml = FXMLLoader~load(url)
  scene = .bsf~new("javafx.scene.Scene", fxml, gd~getDisplayMode~getWidth, gd~getDisplayMode~getHeight)
  stage~setScene(scene)
  scene~getStylesheets~add("file:stylesheet.css")

  stage~setFullScreen(.true)
  stage~show

::METHOD loadScene
  EXPOSE stage FXMLLoader
  USE ARG title, fileName
  stage~setTitle(title)
  url =.bsf~new("java.net.URL", fileName)
  fxml = FXMLLoader~load(url)
  stage~getScene~setRoot(fxml)

::METHOD newWindow
  EXPOSE stage windowStage FXMLLoader
  USE ARG title, fileName
  windowStage = .bsf~new("javafx.stage.Stage")
  windowStage~setTitle(title)
  url =.bsf~new("java.net.URL", fileName)
  fxml = FXMLLoader~load(url)
  scene = .bsf~new("javafx.scene.Scene", fxml)
  scene~getStylesheets~add("stylesheet.css")
  windowStage~setScene(scene)
  windowStage~initModality(bsf.loadClass("javafx.stage.Modality")~WINDOW_MODAL)
  windowStage~initOwner(stage)
  windowStage~show

::METHOD loadMainScene PUBLIC
  self~loadScene("Main", "file:main.fxml")

::METHOD showDialog
  EXPOSE stage
  USE ARG type, title, content
  Alert = bsf.import("javafx.scene.control.Alert")
  AlertType = bsf.import("javafx.scene.control.Alert$AlertType")
  IF type~upper = "WARNING" THEN DO
    alert = Alert~new(AlertType~WARNING)
  END
  ELSE IF type~upper = "ERROR" THEN DO
    alert = Alert~new(AlertType~ERROR)
  END
  ELSE DO
    alert = Alert~new(AlertType~INFORMATION)
  END
  alert~setTitle(title)
  alert~setHeaderText(.nil)
  alert~setContentText(content)
  alert~initOwner(stage)
  alertStage = alert~getDialogPane~getScene~getWindow
  alertStage~setAlwaysOnTop(.true)
  alert~showAndWait



::REQUIRES "setClasspath.rex"
::REQUIRES "DatabaseHandler.CLS"
::REQUIRES "BSF.CLS"
::REQUIRES "functions.rex"
