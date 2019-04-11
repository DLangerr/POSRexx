/**
  * ActiveUser Class keeps track of the currently logged in user
*/

::CLASS ActiveUser PUBLIC
::METHOD id ATTRIBUTE
::METHOD username ATTRIBUTE
::METHOD name ATTRIBUTE
::METHOD surname ATTRIBUTE
::METHOD accessRights ATTRIBUTE
::METHOD INIT
  EXPOSE id username name surname accessRights
  USE ARG id, username, name, surname, accessRights
  