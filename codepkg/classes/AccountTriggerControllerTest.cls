@IsTest
public class AccountTriggerControllerTest {
	private static String PROPERTY_PARCEL_NUMBER = '001-01-011';
	private static String PROPERTY_OWNER_NAME = 'CAPOZIELLO, GREGORY & CANDICE';
	private static Integer PROPERTY_OCCUPANCY = 1;
	private static Integer PROPERTY_AGE = 1950;
	private static String PROPERTY_STREET_NUMBER = '11516';
	private static String PROPERTY_STREET_NAME = 'Edgewater';
	private static String PROPERTY_STREET_SUFFIX = 'Dr';
	private static String PROPERTY_ZIP = '44102';

	@IsTest
	static void beforeInsert_givenExactAddressAndZipMatch_shouldSetMyPlacePropertyAndRelatedFields() {
		String accountAddress = PROPERTY_STREET_NUMBER + ' ' + PROPERTY_STREET_NAME + ' ' + PROPERTY_STREET_SUFFIX;
		Account testAccount = new Account(
				Name = accountAddress,
				Zip_2__c = PROPERTY_ZIP
		);

		Test.startTest();
			insert testAccount;
		Test.stopTest();

		Account insertedTestAccount = [SELECT MyPlace_Property__c, Parcel_Number_2__c, Number_of_Units_2__c, Year_Built_2__c
										FROM Account
										WHERE Name = :accountAddress];

		MyPlace_Property__c testMyPlaceProperty = [SELECT Id, Name, OCCUPANCY__c, AGE__c
													FROM MyPlace_Property__c
													WHERE Name = :PROPERTY_PARCEL_NUMBER];

		System.assertEquals(testMyPlaceProperty.Id, insertedTestAccount.MyPlace_Property__c,
				'The MyPlace Property lookup on the Account should be set to the Id of the MyPlace Property record matching the Account\'s address.');
		System.assertEquals(testMyPlaceProperty.Name, insertedTestAccount.Parcel_Number_2__c,
				'The Parcel Number field on the Account should be set to the Name of the MyPlace Property record matching the Account\'s address.');
		System.assertEquals(testMyPlaceProperty.OCCUPANCY__c, insertedTestAccount.Number_of_Units_2__c,
				'The Number of Units field on the Account should be set to the Occupancy of the MyPlace Property record matching the Account\'s address'
						+ ' when the Units field on the MyPlace Property is 0 or null.');
		System.assertEquals(String.valueOf(testMyPlaceProperty.AGE__c), insertedTestAccount.Year_Built_2__c,
				'The Year Built field on the Account should be set to the Age of the MyPlace Property record matching the Account\'s address.');
	}

	@IsTest
	static void beforeInsert_givenCloseAddressAndZipMatch_shouldTryToSetMyPlacePropertyViaLevenshteinDistance() {
		// Not an exact address match, but close (ie, Drive and not Dr)
		String accountAddress = PROPERTY_STREET_NUMBER + ' ' + PROPERTY_STREET_NAME + ' Drive';
		Account testAccount = new Account(
				Name = accountAddress,
				Zip_2__c = PROPERTY_ZIP
		);

		Test.startTest();
			insert testAccount;
		Test.stopTest();

		Account insertedTestAccount = [SELECT MyPlace_Property__c, Parcel_Number_2__c, Number_of_Units_2__c, Year_Built_2__c
										FROM Account
										WHERE Name = :accountAddress];

		MyPlace_Property__c testMyPlaceProperty = [SELECT Id, Name, OCCUPANCY__c, AGE__c
													FROM MyPlace_Property__c
													WHERE Name = :PROPERTY_PARCEL_NUMBER];

		System.assertEquals(testMyPlaceProperty.Id, insertedTestAccount.MyPlace_Property__c,
				'The MyPlace Property lookup on the Account should be set to the Id of the MyPlace Property record matching the Account\'s address.');
		System.assertEquals(testMyPlaceProperty.Name, insertedTestAccount.Parcel_Number_2__c,
				'The Parcel Number field on the Account should be set to the Name of the MyPlace Property record matching the Account\'s address.');
		System.assertEquals(testMyPlaceProperty.OCCUPANCY__c, insertedTestAccount.Number_of_Units_2__c,
				'The Number of Units field on the Account should be set to the Occupancy of the MyPlace Property record matching the Account\'s address'
						+ ' when the Units field on the MyPlace Property is 0 or null.');
		System.assertEquals(String.valueOf(testMyPlaceProperty.AGE__c), insertedTestAccount.Year_Built_2__c,
				'The Year Built field on the Account should be set to the Age of the MyPlace Property record matching the Account\'s address.');
	}

	@IsTest
	static void beforeInsert_givenWrongAddressAndZipMismatch_shouldNotMatch() {
		String accountAddress = '1234 Wrong Street';
		Account testAccount = new Account(
				Name = accountAddress,
				Zip_2__c = '12345'
		);

		Test.startTest();
			insert testAccount;
		Test.stopTest();

		Account insertedTestAccount = [SELECT MyPlace_Property__c, Parcel_Number_2__c, Number_of_Units_2__c, Year_Built_2__c
										FROM Account
										WHERE Name = :accountAddress];

		System.assertEquals(null, insertedTestAccount.MyPlace_Property__c,
				'The MyPlace Property lookup on the Account should not be set if a matching MyPlace Property does not exist for the given address and zip.');
		System.assertEquals(null, insertedTestAccount.Parcel_Number_2__c,
				'The Parcel Number field on the Account should not be automatically set if a matching MyPlace Property does not exist for the given address and zip.');
		System.assertEquals(null, insertedTestAccount.Number_of_Units_2__c,
				'The Number of Units field on the Account should not be automatically set if a matching MyPlace Property does not exist for the given address and zip.');
		System.assertEquals(null, insertedTestAccount.Year_Built_2__c,
				'The Year Built field on the Account should not be automatically set if a matching MyPlace Property does not exist for the given address and zip.');
	}

	@TestSetup
	static void createMyPlacePropertyForInsert() {
		MyPlace_Property__c testMyPlaceProperty = new MyPlace_Property__c(
				Name = PROPERTY_PARCEL_NUMBER,
				PARCEL_ID__c = '101011',
				DEEDED_OWNER__c = PROPERTY_OWNER_NAME,
				UNITS__c = 0,
				OCCUPANCY__c = PROPERTY_OCCUPANCY,
				AGE__c = PROPERTY_AGE,
				STREET_NUMBER__c = PROPERTY_STREET_NUMBER,
				STREET_DIR__c = null,
				STREET_NAME__c = PROPERTY_STREET_NAME,
				STREET_SUFFIX__c = PROPERTY_STREET_SUFFIX,
				CITY__c = 'Cleveland',
				STATE__c = 'OH',
				ZIP__c = PROPERTY_ZIP
		);

		insert testMyPlaceProperty;
	}
}