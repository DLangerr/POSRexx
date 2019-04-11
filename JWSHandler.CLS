/**
  * JWSHandler Class creates JWS Signature that are used for the QR Codes on receipts
*/

::CLASS JWSHandler PUBLIC
::METHOD MessageDigest ATTRIBUTE
::METHOD StandardCharsets ATTRIBUTE
::METHOD System ATTRIBUTE
::METHOD Encoder ATTRIBUTE
::METHOD Decoder ATTRIBUTE
::METHOD UrlDecoder ATTRIBUTE
::METHOD KeyPairGenerator ATTRIBUTE
::METHOD SecureRandom ATTRIBUTE
::METHOD Signature ATTRIBUTE
::METHOD INIT
  EXPOSE MessageDigest StandardCharsets System Encoder Decoder KeyPairGenerator SecureRandom UrlDecoder
  StandardCharsets = bsf.import("java.nio.charset.StandardCharsets")
  System = bsf.import("java.lang.System")
  Base64 = bsf.import("java.util.Base64")
  Encoder = Base64~Encoder
  Decoder = Base64~Decoder
  UrlDecoder = Base64~getUrlDecoder
  KeyPairGenerator = bsf.loadClass("java.security.KeyPairGenerator")
  SecureRandom = bsf.import("java.security.SecureRandom")
  MessageDigest = bsf.loadClass("java.security.MessageDigest")

::METHOD hashLastReceipt PUBLIC
  EXPOSE MessageDigest StandardCharsets System 
  USE ARG str, N=8
  jStr = box("STring", str)

  digest = MessageDigest~getInstance("SHA-256")
  hash = digest~digest(jStr~getBytes(StandardCharsets~UTF_8))

  /* Copy N Bytes */
  conDigest = bsf.CreateJavaArray("byte.class", N)
  System~arraycopy(hash, 0, conDigest, 0, N)

  RETURN self~base64Encode(conDigest)

::METHOD base64Encode PUBLIC
  EXPOSE Encoder
  USE ARG str
  RETURN Encoder~encodeToString(str)

::METHOD encryptECDSA PUBLIC
  USE ARG payload, privateKey

  JsonWebSignature = bsf.import("org.jose4j.jws.JsonWebSignature")
  jws = JsonWebSignature~new
  jws~setKey(privateKey)
  jws~setPayload(payload)
  jws~setAlgorithmHeaderValue("ES256")
  jws~sign
  RETURN jws~getCompactSerialization

::METHOD privateKeyFromString PUBLIC
  EXPOSE Decoder
  USE ARG keyString
  PKCS8EncodedKeySpec = bsf.import("java.security.spec.PKCS8EncodedKeySpec")
  kf = bsf.loadClass("java.security.KeyFactory")~getInstance("EC")
  privateBytes = Decoder~decode(keyString)

  RETURN kf~generatePrivate(PKCS8EncodedKeySpec~new(privateBytes))

::METHOD generateKeyPair
  EXPOSE KeyPairGenerator SecureRandom
  keyGen = KeyPairGenerator~getInstance("EC")
  random = SecureRandom~getInstance("SHA1PRNG")
  keyGen~initialize(256, random)
  RETURN keyGen~generateKeyPair

::METHOD recode PUBLIC
  EXPOSE Encoder UrlDecoder
  USE ARG base64URL
  decoded = UrlDecoder~decode(base64URL)
  RETURN Encoder~encodeToString(decoded)

::METHOD restoreQRString PUBLIC
  EXPOSE UrlDecoder
  USE ARG payload, signature
  IF payload = .nil THEN DO
    RETURN .my.app~dbh~getBusinessInformation()["CashRegisterID"]
  END

  decodedPayloadBytes = UrlDecoder~decode(payload)
  decodedPayload = BsfRawBytes(decodedPayloadBytes)
  sigBase64 = self~recode(signature)

  RETURN decodedPayload || "_" || sigBase64

::REQUIRES "BSF.CLS"