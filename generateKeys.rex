PARSE SOURCE . . fullPath
CALL directory filespec('L', fullPath)

fileName = "key" || time("S") || ".txt"
aes = .AES256~new
jwsHandler = .JWSHandler~new
Base64 = bsf.import("java.util.Base64")
Encoder = Base64~getEncoder

SAY "Creating file" fileName || "."
file = .stream~new(fileName)
file~open("both replace")

SAY "Generating AES key..."
key = aes~generateAES256Key
SAY "Writing AES key..."
file~lineout("AES256 Key:" key)
SAY "Calculating hash..."
checkSum = aes~calcCheckSumFromKey(key)
SAY "Writing hash..."
file~lineout("Checksum:" checkSum)
SAY "Checking hash..." 
IF aes~checkValSum(key, checkSum) THEN DO
  msg = "Checksum successfully calculated."
  SAY "[+] Successfully generated AES256 key."
END
ELSE DO
  msg = "Error calculating checksum."
  SAY "[-] ERROR: Generating AES256 key unsuccessful."
END
file~lineout(msg)
file~lineout("========================")

SAY "Generating key pair..."
keyPair = jwsHandler~generateKeyPair
priv = keyPair~getPrivate~getEncoded
pub = keyPair~getPublic~getEncoded
SAY "Writing key pair..."
file~lineout("Private Key:" Encoder~encodeToString(priv))
file~lineout("Public Key:" Encoder~encodeToString(pub))
SAY "[+] Success generated key pair."
file~close
SAY "Press enter to quit."
PARSE PULL .

::REQUIRES "AES256.CLS"
::REQUIRES "JWSHandler.CLS"