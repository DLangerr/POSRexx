Requirements:
- ooRexx (Recommended Version 5.0.0): https://sourceforge.net/projects/oorexx/files/oorexx/
- Java JDK (Recommended Version 8): https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
Alternative: OpenJDK (Recommended Version 8: https://adoptopenjdk.net/
- BSF4ooRexx: https://sourceforge.net/projects/bsf4oorexx/
- MySQL: (Recommended Version 8): https://dev.mysql.com/downloads/windows/installer/8.0.html
The included Jconnector .jar needs to be copied/moved to the /bin/ folder of the POSRexx software

All the following JARs need to be included in the /bin/ folder of the POSRexx software or added to the CLASSPATH environment variable
==============================================================================================================

- Zxing: core-3.3.3.jar and javase-3.3.3.jar (or similar versions): https://github.com/zxing/zxing/wiki/Getting-Started-Developing
- Jfoenix: jfoenix-8.0.8.jar (or similar versions): https://github.com/jfoenixadmin/JFoenix
- Jose4J: jose4j-0.6.5.jar (or similar versions): https://bitbucket.org/b_c/jose4j/downloads/
- SLF4j: slf4j-api-1.7.25.jar and slf4j-simple-1.7.25.jar (or similar versions): https://www.slf4j.org/download.html

Optional:
For editing the GUI: Scene Builder: https://gluonhq.com/products/scene-builder/


==============================================================================================================
==============================================================================================================
Running the program:
	- setup.rex (Required): 2 command line arguments: MySQL username and password (if none given default to "root" and "password")
			--> generates conf.ini
		In case of unsuccesful database connection: Modify conf.ini and make sure MySQL server is running
			--> Run setup.rex again
	
	- generateKeys.rex (Optional): Generates keys and writes it in .txt file. These will be required when running the main program.
	- fillDatabase.rex (Optional): For testing purposes the database can be filled with random orders.
									The amount of orders can be specified in the first command line argument. (default=500)
	
	- main.rex: will run the main program. Will not work without running setup.rex first.
									