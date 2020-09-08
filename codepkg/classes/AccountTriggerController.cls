public class AccountTriggerController {

	public void beforeInsert(List<Account> newAccounts) {
		setMyPlaceDataOnAccounts(newAccounts);
	}

	public void afterInsert(List<Account> newAccounts) {
		createClientContactsForAccounts(newAccounts);
	}

	private void setMyPlaceDataOnAccounts(List<Account> newAccounts) {
		for (Account acc : newAccounts) {
			// Note: This is doing SOQL in a loop. getMyPlaceProperty() is not bulkified and cannot be bulkified.
			// Be careful when inserting more than a few Accounts
			MyPlace_Property__c matchingMyPlaceProperty = getMyPlaceProperty(acc);

			// Skip records where a MyPlace Property couldn't be matched
			if (matchingMyPlaceProperty == null) {
				continue;
			}

			acc.MyPlace_Property__c = matchingMyPlaceProperty.Id;
			acc.Parcel_Number_2__c = matchingMyPlaceProperty.Name; // Name on MyPlace_Property__c is the Parcel Number

			// If there isn't any number for the given units, use the occupancy instead
			if (matchingMyPlaceProperty.UNITS__c == null || matchingMyPlaceProperty.UNITS__c == 0) {
				acc.Number_of_Units_2__c = matchingMyPlaceProperty.OCCUPANCY__c;
			} else {
				acc.Number_of_Units_2__c = matchingMyPlaceProperty.UNITS__c;
			}

			// The Property Owner isn't being mapped here
			// Instead, it is being pulled up onto Account with a formula field, MyPlace_Property_Owner__c

			// The year is optional on the Heritage Home Consultation scheduling form.
			// If it's given, we don't want to overwrite it. As such, we only set it if it's blank
			if (String.isBlank(acc.Year_Built_2__c)) {
				acc.Year_Built_2__c = String.valueOf(matchingMyPlaceProperty.AGE__c);
			}
		}
	}

	// The MyPlace Property-setting code unfortunately cannot be bulkified. There are 550k MyPlace Properties records,
	// which would run into the SOQL record limit immediately if we tried to query all of them and then sort afterwards.
	// Returns null if the MyPlace Property can't be found
	private MyPlace_Property__c getMyPlaceProperty(Account accountToMatchProperty) {
		MyPlace_Property__c bestMatchMyPlaceProperty;
		String accountAddress = accountToMatchProperty.Name.toUpperCase();
		String accountStreetNumber = accountAddress.split(' ')[0];

		// Selecting by zip and street number to first to limit the number of MyPlace Property records we get
		// There's 550k records and that would run into the SOQL limit, so we unfortunately can't select all
		// While we could select by city as well, the county's data has a LOT of incorrect city names
		// There's some bad zip codes, but much fewer than the bad cities
		List<MyPlace_Property__c> possibleMyPlaceProperties = [
			SELECT Name, Address__c, STREET_NUMBER__c, CITY__c, ZIP__c, UNITS__c, OCCUPANCY__c, AGE__c, DEEDED_OWNER__c
			FROM MyPlace_Property__c
			WHERE ZIP__c = :accountToMatchProperty.Zip_2__c
				AND STREET_NUMBER__c = :accountStreetNumber
		];

		// The Levenshtein distance between two strings is the minimum number of single-character edits required to change one string into the other
		// It helps us find the best address match for the MyPlace Property
		// Starting it off impossibly high so the first MyPlace Property we check is a better match
		Integer bestMatchDistance = 999999999;
		for (MyPlace_Property__c possibleMyPlaceProperty : possibleMyPlaceProperties) {
			// Checking by upper case to get rid of distance issues from capitalization, which don't matter here
			String possibleMyPlacePropertyAddress = possibleMyPlaceProperty.Address__c.toUpperCase();
			// If we find the exact property, we're all done! No more looping
			if (possibleMyPlacePropertyAddress == accountAddress) {
				bestMatchMyPlaceProperty = possibleMyPlaceProperty;
				break;
			}

			Integer currentDistance = possibleMyPlacePropertyAddress.getLevenshteinDistance(accountAddress);
			if (currentDistance < bestMatchDistance) {
				bestMatchDistance = currentDistance;
				bestMatchMyPlaceProperty = possibleMyPlaceProperty;
			}
		}

		return bestMatchMyPlaceProperty;
	}

	private void createClientContactsForAccounts(List<Account> newAccounts) {
		List<Inquiry__c> clientContactsToCreate = new List<Inquiry__c>();
		for (Account insertedAccount : newAccounts) {
			Inquiry__c newClientContact = new Inquiry__c(
					NewProperty__c = insertedAccount.Id,
					Contact__c = insertedAccount.Property_Owner_2__c, //TODO: Property_Owner_2__c isn't being set yet
					Date__c = insertedAccount.CreatedDate,
					Note__c = 'Initial Inquiry'
			);
			clientContactsToCreate.add(newClientContact);
		}
		insert clientContactsToCreate;
	}
}