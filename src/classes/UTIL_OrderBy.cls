public with sharing class UTIL_OrderBy {

    public enum SortingOrder { ASCENDING, DESCENDING }

	private List<Field> fields;
	private Boolean isPostSort = false;

	public UTIL_OrderBy() {
		fields = new List<Field>();
	}

	public UTIL_OrderBy add(Field field) {
		fields.add(field);
		return this;
	}

	public String build() {
		List<String> orderBy = new List<String>();

		if (fields.isEmpty()) {
			return '';
		}

		for (Field field : fields) {
			if (!field.isSortable()) {
				isPostSort = true;
				return '';

			} else {
				orderBy.add(field.toString());
			}
		}

		return String.join(orderBy, ', ');
	}

	public List<sObject> sort(List<sObject> records) {
		if (!isPostSort) {
			return records;
		}

		List<sObject> sortedRecords = new List<sObject>();
		for (Integer index = fields.size() - 1; index >= 0; index--) {
			sortedRecords = sort(records, fields[index]);
		}

		return sortedRecords;
	}

	/*******************************************************************************************************
	* @description Sorts records by the field
	*/
	public List<sObject> sort(List<sObject> records, Field field) {
		if (field.isNameField()) {
			records.sort();
			return records;
		} 

		String fieldName = field.getFieldName();
		Boolean isSortDesc = field.isDesc();
		List<SortableRecord> sortableRecords = new List<SortableRecord>();

		for (sObject record : records) {
			sortableRecords.add(new SortableRecord(record, fieldName, isSortDesc));
		}
		sortableRecords.sort();

		List<sObject> sortedRecords = new List<sObject>();
		for (SortableRecord rec : sortableRecords) {
			sortedRecords.add(rec.getRecord());
		}

		return sortedRecords;
	}

	public class SortableRecord implements Comparable {
		private sObject record;
		private String value;
		private Boolean isSortDesc;

		public SortableRecord(sObject record, String fieldName, Boolean isSortDesc) {
			this.record = record;
			this.value = (String) record.get(fieldName);
			this.isSortDesc = isSortDesc;
		}

		public sObject getRecord() {
			return record;
		}

		public Integer compareTo(Object other) {
			String otherValue = ((SortableRecord) other).value;
			otherValue = String.isBlank(otherValue) ? '' : otherValue;

			Integer result = value.compareTo(otherValue);

			return (isSortDesc ? -1 : 1) * result;
		}
	}


	public class Field {
		Schema.sObjectField sObjField;
		String sortOrder;
		String nullOrder;
		Boolean isDesc;
		String fieldName;

		/*******************************************************************************************************
		* @description Constructors
		*/
		public Field(Schema.sObjectField sObjField) {
			this(sObjField, '');
		}

		public Field(Schema.sObjectField sObjField, String sortOrder) {
			this(sObjField, sortOrder, '');
		}

		public Field(Schema.sObjectField sObjField, String sortOrder, String nullOrder) {
			this.sObjField = sObjField;
			this.sortOrder = String.isBlank(sortOrder) ? '' : sortOrder;
			this.nullOrder = String.isBlank(nullOrder) ? '' : 'NULLS ' + nullOrder;

			this.fieldName = String.valueOf(this.sObjField);
			this.isDesc = this.sortOrder.equalsIgnoreCase('desc');
		}

        public Field withRelationship(Schema.sObjectField referenceField) {
			fieldName = referenceField.getDescribe().getRelationshipName() + '.' + fieldName;

            return this;
        }

		/*******************************************************************************************************
		* @description Returns if the field is sortable. If the field is encrypted, the return is "false".
		*/
		public Boolean isSortable() {
			return sObjField.getDescribe().isSortable();
		}

		/*******************************************************************************************************
		* @description Returns if sorting is descending
		*/
		public Boolean isDesc() {
			return isDesc;
		}

		/*******************************************************************************************************
		* @description Returns if the field is a Name.
		*/
		public Boolean isNameField() {
			return sObjField.getDescribe().isNameField();
		}

		/*******************************************************************************************************
		* @description Returns field name
		*/
		public String getFieldName() {
			return fieldName;
		}

		/*******************************************************************************************************
		* @description Returns ORDER BY clause segment for this field
		*/
		public override String toString() {
			return String.format('{0} {1} {2}', new String[] { fieldName, sortOrder, nullOrder }); 
		}
	}

}