/**
    * JWSHandler Class creates 300x300 QR Codes
*/

::CLASS QRWriter PUBLIC
::METHOD BarcodeFormat ATTRIBUTE
::METHOD BitMatrix ATTRIBUTE
::METHOD QRCodeWriter ATTRIBUTE
::METHOD MatrixToImageWriter ATTRIBUTE
::METHOD INIT
  EXPOSE BarcodeFormat BitMatrix QRCodeWriter MatrixToImageWriter

  BarcodeFormat = bsf.import("com.google.zxing.BarcodeFormat")
  BitMatrix = bsf.import("com.google.zxing.common.BitMatrix")
  QRCodeWriter = bsf.import("com.google.zxing.qrcode.QRCodeWriter")
  MatrixToImageWriter = bsf.import("com.google.zxing.client.j2se.MatrixToImageWriter")

::METHOD write
  EXPOSE BarcodeFormat BitMatrix QRCodeWriter MatrixToImageWriter
  USE ARG path, qrString

  path = .bsf~new("java.io.File", path)

  writer = QRCodeWriter~new
  bitMatrix = writer~encode(qrString, BarcodeFormat~QR_CODE, 300, 300)
  MatrixToImageWriter~writeToFile(bitMatrix, "PNG", path)



::REQUIRES "BSF.CLS"
