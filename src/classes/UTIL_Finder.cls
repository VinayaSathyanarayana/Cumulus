/*
    Copyright (c) 2018, Salesforce.org
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
* @description SObject Finder
*/
public with sharing class UTIL_Finder {
    private sObjectType sObjType;
    private Set<String> selectFields {
        get {
            if (selectFields == null) {
                selectFields = new Set<String>{'Id'};
            }
            return selectFields;
        }
        set;
    }
    private String condition;
    private OrderByClause orderByClause;

    /*******************************************************************************************************************
    * @description UTIL_Finder constructor for the provided sObject Type
    */
    public UTIL_Finder(sObjectType sObjType) {
        this.sObjType = sObjType;
        this.orderByClause = new OrderByClause();
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with all passed in select fields
    */
    public UTIL_Finder withSelectFieldsFromReference(Set<Schema.sObjectField> sObjFields, Schema.SObjectField referenceField) {
        for (Schema.sObjectField sObjField : sObjFields) {
            selectFields.add(referenceField.getDescribe().getRelationshipName() + '.' + String.valueOf(sObjField));
        }

        return this;
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with all passed in select fields
    */
    public UTIL_Finder withSelectFields(Set<Schema.sObjectField> sObjFields) {
        for (Schema.sObjectField sObjField : sObjFields) {
            selectFields.add(String.valueOf(sObjField));
        }

        return this;
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with passed in order by field
    */
    public UTIL_Finder withOrderBy(Schema.sObjectField sObjField) {
        return withOrderBy(new List<Schema.sObjectField>{ sObjField });
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with passed in order by fields
    */
    public UTIL_Finder withOrderBy(List<Schema.sObjectField> sObjFields) {
        for (Schema.sObjectField sObjField : sObjFields) {
            orderByClause.add(sObjField);
        }

        return this;
    }

    /*******************************************************************************************************************
    * @description Returns all sObjects for this sObject Type
    */
    public List<sObject> findAll() {
        List<sObject> sObjects = Database.query(buildQuery());

        return orderByClause.sort(sObjects);
    }

    /*******************************************************************************************************************
    * @description Returns all sObjects for this sObject Type
    */
    public List<sObject> findByRelatedToIds(Schema.sObjectField referenceField, Set<Id> relatedToIds) {
        condition = String.valueOf(referenceField) + ' IN :relatedToIds';
        List<sObject> sObjects = Database.query(buildQuery());

        return orderByClause.sort(sObjects);
    }

    private String buildQuery() {
        String query = new UTIL_Query()
                .withFrom(sObjType)
                .withSelectFields(selectFields)
                .withWhere(String.isEmpty(condition) ? null : condition)
                .withOrderBy(orderByClause.build())
                .build();

        return query;
    }



    /*******************************************************************************************************
    * @description OrderByClause
    */
    public class OrderByClause {
        private List<Field> fields;
        private Boolean isPostSort = false;

        public OrderByClause add(Field field) {
            fields.add(field);
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

            //Can we wrap the sObject into a Comparable class, store records in a list
            //and then just use the list.sort() and traverse it to extract the sObject?
            Map<String, List<sObject>> recordsBySortValue = new Map<String, List<sObject>>();
            List<String> values = new List<String>();

            for (sObject record : records){
                String value = record.get(field.getName()).toString();
                values.add(value);

                if (!recordsBySortValue.containsKey(value)) {
                    recordsBySortValue.put(value, new List<sObject>());
                }
                recordsBySortValue.get(value).add(record);
            }

            values.sort();

            Integer size = values.size();
            List<sObject> sortedRecords = new sObject[size];

            for (Integer i = 0; i < size;  i++) {
                Integer index = isDesc ? size - i - 1 : i;
                sortedRecords[index] = recordsBySortValue.get(values[i]);
            }
            return sortedRecords;
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

            /*******************************************************************************************************
            * @description Returns if the field is sortable. If the field is encrypted, the return is "false".
            */
            public Boolean isSortable() {
                return sObjField.getDescribe().isSortable();
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
            public Boolean getName() {
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



/*
    public class OrderBy {
        Schema.sObjectField referenceField;//Contact.AccountId --> Lookup/M-D

        public OrderBy withReferenceField(Schema.sObjectField referenceField) {
            this.referenceField = referenceField;

            return this;
        }

        private String getOrderByField() {
            return referenceField == null ? 
                String.valueOf(field) :
                referenceField.getDescribe().getRelationshipName() + '.' + String.valueOf(field);
        }
    }
    */
}