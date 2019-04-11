/**
  * JWSHandler Class creates PBKDF2 hashes and generates new random salts
*/

::CLASS PasswordHasher PUBLIC
::METHOD DatatypeConverter ATTRIBUTE
::METHOD INIT
  EXPOSE DatatypeConverter
  DatatypeConverter = bsf.import("javax.xml.bind.DatatypeConverter")

::METHOD generatePasswordHash PUBLIC
  USE ARG password, salt

  SecretKeyFactory = bsf.import("javax.crypto.SecretKeyFactory")
  PBEKeySpec = bsf.import("javax.crypto.spec.PBEKeySpec")

  iterationCount = 100000
  keyLength = 160

  passwordCharArr = self~stringToJavaCharArray(password)
  spec = PBEKeySpec~new(passwordCharArr, salt, iterationCount, keyLength)
  factory = SecretKeyFactory~getInstance("PBKDF2WithHmacSHA1")
  hash = factory~generateSecret(spec)~getEncoded
  hashString = self~byteArrayToHexString(hash)
  RETURN hashString

::METHOD generateRandomSalt PUBLIC
  random = .bsf~new("java.security.SecureRandom")
  salt = bsf.createArray("byte.class", 16)
  random~nextBytes(salt)
  RETURN salt

::METHOD byteArrayToHexString PUBLIC
  USE ARG byteArr
  RETURN C2X(BsfRawBytes(byteArr))

::METHOD hexStringToByteArray PUBLIC
  USE ARG hexString
  RETURN BsfRawBytes(X2C(hexString))

::METHOD stringToJavaCharArray PUBLIC
  USE ARG inputString
  len = length(inputString)
  byteArr = bsf.createJavaArray("char.class", len)
  DO i=1 TO len
    byteArr[i] = inputString[i]
  END
  RETURN byteArr
  
::REQUIRES "BSF.CLS"