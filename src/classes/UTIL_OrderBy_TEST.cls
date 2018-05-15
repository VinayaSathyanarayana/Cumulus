/*
    Copyright (c) 2018 Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2018
* @group Utilities
* @description Unit tests for UTIL_OrderBy class
*/
@isTest
private class UTIL_OrderBy_TEST {
	private static final UTIL_OrderBy.SortingOrder SORT_DESC = UTIL_OrderBy.SortingOrder.DESCENDING;
	private static final UTIL_OrderBy.SortingOrder SORT_ASC = UTIL_OrderBy.SortingOrder.ASCENDING;
	private static final UTIL_OrderBy.NullsOrder NULLS_FIRST = UTIL_OrderBy.NullsOrder.FIRST;
	private static final UTIL_OrderBy.NullsOrder NULLS_LAST = UTIL_OrderBy.NullsOrder.LAST;
	 
	@isTest static void toStringReturnsOrderByForField() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name);

		System.assertEquals('Name', field.toString());
	}

	@isTest static void toStringReturnsOrderByForFieldAndDescSortOrder() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_DESC);

		System.assertEquals('Name DESC', field.toString());
	}

	@isTest static void toStringReturnsOrderByForFieldAndAscSortOrder() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_ASC);

		System.assertEquals('Name', field.toString());
	}

	@isTest static void toStringReturnsOrderByForFieldAndSortOrderAndNullOrderLast() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_DESC, NULLS_LAST);

		System.assertEquals('Name DESC NULLS LAST', field.toString());
	}

	@isTest static void toStringReturnsOrderByForFieldAndSortOrderAndNullOrderFirst() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_DESC, NULLS_FIRST);

		System.assertEquals('Name DESC', field.toString());
	}

	@isTest static void toStringReturnsOrderByForRelationshipField() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name).withRelationship(Contact.AccountId);

		System.assertEquals('Account.Name', field.toString());
	}

	@isTest static void getFieldNameReturnsName() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name);

		System.assertEquals('Name', field.getFieldName());
	}

	@isTest static void getFieldNameReturnsNameForTheRelationshipField() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name).withRelationship(Contact.AccountId);

		System.assertEquals('Account.Name', field.getFieldName());
	}

	@isTest static void isNameFieldReturnsTrueForNameField() {
		System.assert(new UTIL_OrderBy.Field(Account.Name).isNameField());
		System.assert(new UTIL_OrderBy.Field(Contact.Name).isNameField());
	}

	@isTest static void isNameFieldReturnsFalseWhenFieldIsNotName() {
		System.assert(!new UTIL_OrderBy.Field(Account.BillingCity).isNameField());
		System.assert(!new UTIL_OrderBy.Field(Contact.FirstName).isNameField());
		System.assert(!new UTIL_OrderBy.Field(Contact.LastName).isNameField());
	}

	@isTest static void isSortDescReturnsTrueForDescSortOrder() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_DESC);

		System.assert(field.isSortDesc());
	}

	@isTest static void isSortDescReturnsFalseForAscSortOrder() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_ASC);

		System.assert(!field.isSortDesc());
	}

	@isTest static void compareToReturnsZeroWhenValuesAreTheSame() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name);
		UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
		UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);

		System.assertEquals(0, record.compareTo(other));
	}

	@isTest static void compareToIsCaseSensitive() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name);
		UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
		UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'FOO'), field);

		System.assert(record.compareTo(other) < 0);
	}

	@isTest static void compareToReturnsPositiveNumberWhenValuePreceedsOther() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name);
		UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
		UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'xyz'), field);

		System.assert(record.compareTo(other) > 0);
	}

	@isTest static void compareToReturnsNegativeNumberForDescOrder() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_DESC);
		UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
		UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'xyz'), field);

		System.assert(record.compareTo(other) < 0);
	}

	@isTest static void compareToReturnsNegativeNumberWhenValueFollowsOther() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name);
		UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
		UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'abc'), field);

		System.assert(record.compareTo(other) < 0);
	}

	@isTest static void compareToReturnsPositiveNumberForDescOrder() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_DESC);
		UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
		UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'abc'), field);

		System.assert(record.compareTo(other) > 0);
	}

	@isTest static void compareToReturnsPositiveNumberWhenOtherIsNullAscOrderNullsLast() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_ASC, NULLS_LAST);
		UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
		UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(), field);

		System.assert(record.compareTo(other) > 0);
	}

	@isTest static void compareToReturnsNegativeNumberWhenOtherIsNullAscOrderNullsFirst() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_ASC, NULLS_FIRST);
		UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
		UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(), field);

		System.assert(record.compareTo(other) < 0);
	}

	@isTest static void compareToReturnsPositiveNumberWhenOtherIsNullDescOrderNullsLast() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_DESC, NULLS_LAST);
		UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
		UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(), field);

		System.assert(record.compareTo(other) > 0);
	}

	@isTest static void compareToReturnsNegativeNumberWhenOtherIsNullDescOrderNullsFirst() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_DESC, NULLS_FIRST);
		UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
		UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(), field);

		System.assert(record.compareTo(other) < 0);
	}

	@isTest static void compareToReturnsNegativeNumberWhenValueIsNullAscOrderNullsLast() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_ASC, NULLS_LAST);
		UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(), field);
		UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);

		System.assert(record.compareTo(other) < 0);
	}

	@isTest static void compareToReturnsPositiveNumberWhenValueIsNullAscOrderNullsFirst() {
		UTIL_OrderBy.Field field = new UTIL_OrderBy.Field(Account.Name, SORT_ASC, NULLS_FIRST);
		UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(), field);
		UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);

		System.assert(record.compareTo(other) > 0);
	}


	@isTest static void sortSortsRecordsManuallyWhenTheFieldIsNotSortable() {
		UTIL_OrderBy orderBy = new UTIL_OrderBy();
		orderBy.add(new UTIL_OrderBy.Field(Contact.LastName));
		orderBy.isPostSort = true;

		List<sObject> records = new List<sObject>{
			new Contact(LastName = 'xyz'),
			new Contact(LastName = 'foo'),
			new Contact(LastName = 'abc')
		};

		List<sObject> sortedRecords = orderBy.sort(records);
		System.assertEquals('abc', (String) sortedRecords[0].get('LastName'));
		System.assertEquals('foo', (String) sortedRecords[1].get('LastName'));
		System.assertEquals('xyz', (String) sortedRecords[2].get('LastName'));
	}

	@isTest static void sortSortsRecordsManuallyWhenFieldsAreNotSortable() {
		UTIL_OrderBy orderBy = new UTIL_OrderBy();
		orderBy.add(new UTIL_OrderBy.Field(Contact.LastName));
		orderBy.add(new UTIL_OrderBy.Field(Contact.FirstName));
		orderBy.isPostSort = true;

		List<sObject> records = new List<sObject>{
			new Contact(LastName = 'xyz', FirstName = 'bar'),
			new Contact(LastName = 'foo', FirstName = 'zbar'),
			new Contact(LastName = 'foo', FirstName = 'abar'),
			new Contact(LastName = 'abc', FirstName = 'bar')
		};

		List<sObject> sortedRecords = orderBy.sort(records);
		System.assertEquals('abc', (String) sortedRecords[0].get('LastName'));
		System.assertEquals('abar', (String) sortedRecords[1].get('FirstName'));
		System.assertEquals('zbar', (String) sortedRecords[2].get('FirstName'));
		System.assertEquals('xyz', (String) sortedRecords[3].get('LastName'));
	}






}