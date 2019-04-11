/**
  * AES256 Class provides AES256 Message encryption and decryption
  * Additionally, it is able to create new AES256 keys and also checksums to verify their integrity 
*/

::CLASS AES256 PUBLIC
::METHOD KeyGenerator ATTRIBUTE
::METHOD Base64 ATTRIBUTE
::METHOD SecretKeySpec ATTRIBUTE
::METHOD Cipher ATTRIBUTE
::METHOD INIT
  EXPOSE KeyGenerator Base64 SecretKeySpec Cipher
  KeyGenerator = bsf.import("javax.crypto.KeyGenerator")
  Base64 = bsf.import("java.util.Base64")
  SecretKeySpec = bsf.import("javax.crypto.spec.SecretKeySpec")
  Cipher = bsf.import("javax.crypto.Cipher")

::METHOD generateAES256Key PUBLIC
  EXPOSE KeyGenerator Base64 

  keyGen = KeyGenerator~getInstance("AES")
  keyGen~bsf.invoke("init", 256)
  secretKey = keyGen~generateKey
  encodedSecKey = secretKey~getEncoded 
  Encoder = Base64~Encoder
  base64Key = Encoder~encodeToString(encodedSecKey)
  RETURN base64Key

::METHOD encrypt PUBLIC
  EXPOSE Base64 SecretKeySpec Cipher
  USE ARG message, secretKey

  Decoder = Base64~Decoder
  encodedSecKey = Decoder~decode(secretKey)
  secKeySpec = SecretKeySpec~new(encodedSecKey, "AES")
  c = Cipher~getInstance("AES")
  c~bsf.invoke("init", Cipher~ENCRYPT_MODE, secKeySpec)
  encrypted = c~doFinal(BsfRawBytes(message))
  Encoder = Base64~Encoder
  encoded = Encoder~encodeToString(encrypted)
  RETURN encoded

::METHOD decrypt PUBLIC
  EXPOSE Base64 SecretKeySpec Cipher
  USE ARG encryptedMessage, secretKey

  Decoder = Base64~Decoder
  encodedSecKey = Decoder~decode(secretKey)
  encryptedMessage = Decoder~decode(encryptedMessage)
  secKeySpec = SecretKeySpec~new(encodedSecKey, "AES")
  c = Cipher~getInstance("AES")
  c~bsf.invoke("init", Cipher~DECRYPT_MODE, secKeySpec)
  message = c~doFinal(encryptedMessage)
  RETURN BsfRawBytes(message)

::METHOD calcCheckSumFromKey PUBLIC
  EXPOSE Base64
  USE ARG base64AESKey, N=3
  md = bsf.loadClass("java.security.MessageDigest")~getInstance("SHA-256")

  sha256hash = md~digest(BsfRawBytes(base64AESKey))
  sha256hashNbytes = bsf.createJavaArray("byte.class", N)
  bsf.loadClass("java.lang.System")~arraycopy(sha256hash, 0, sha256hashNbytes, 0, N)
  Encoder = Base64~Encoder
  base64sha256hashNbytes =  Encoder~encodeToString(sha256hashNbytes)
  valSumCalc = translate(base64sha256hashNbytes, "", "=")
  return valSumCalc

::METHOD checkValSum PUBLIC
  USE ARG base64AESKey, userCheckSum, N=3
  calculatedCheckSum = self~calcCheckSumFromKey(base64AESKey, N)
  return calculatedCheckSum == userCheckSum

::REQUIRES "BSF.CLS"