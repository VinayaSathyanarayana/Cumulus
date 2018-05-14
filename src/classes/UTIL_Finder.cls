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
    private List<OrderBy> orderByFields;
    private String condition;
    private Boolean requiresPostSort;
    private Boolean requiresSosl;

    /*******************************************************************************************************************
    * @description UTIL_Finder constructor for the provided sObject Type
    */
    public UTIL_Finder(sObjectType sObjType) {
        this.sObjType = sObjType;
        orderByFields = new List<OrderBy>();

        requiresPostSort = false;
        requiresSosl = false;
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with all passed in select fields
    */
    public UTIL_Finder withSelectFieldsFromReference(Set<Schema.sObjectField> sObjFields, Schema.SObjectField sObjReferenceField) {
        for (Schema.sObjectField sObjField : sObjFields) {
            selectFields.add(sObjReferenceField.getDescribe().getRelationshipName() + '.' + String.valueOf(sObjField));
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
    public UTIL_Finder withOrderBy(OrderBy orderByField) {
        return withOrderBy(new List<OrderBy>{orderByField});
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with passed in order by fields
    */
    public UTIL_Finder withOrderBy(List<OrderBy> orderByFields) {
        this.orderByFields.addAll(orderByFields);

        return this;
    }

    /*******************************************************************************************************************
    * @description Returns all sObjects for this sObject Type
    */
    public List<sObject> findAll() {
        List<sObject> sObjects = Database.query(buildQuery());

        return sortSObjects(sObjects);
    }

    /*******************************************************************************************************************
    * @description Returns all sObjects for this sObject Type
    */
    public List<sObject> findByRelatedToIds(Schema.sObjectField referenceField, Set<Id> relatedToIds) {
        condition = String.valueOf(referenceField) + ' IN :relatedToIds';
        List<sObject> sObjects = Database.query(buildQuery());

        return sortSObjects(sObjects);
    }

    private String buildQuery() {
        String query = new UTIL_Query()
                .withFrom(sObjType)
                .withSelectFields(selectFields)
                .withWhere(String.isEmpty(condition) ? null : condition)
                .withOrderBy(buildOrderBy())
                .build();

        return query;
    }

    private String buildOrderBy() {
        if (orderByFields.isEmpty()) {
            return '';
        }

        String orderBy = '';

        for (OrderBy orderByField : orderByFields) {
            if (!orderByField.isSortable()) {
                requiresPostSort = true;
                orderBy = '';
                break;
            } else {
                if (String.isNotEmpty(orderBy)) {
                    orderBy += ', ';
                }
                orderBy += orderByField.toString();
            }
        }

        return orderBy;
    }

    private List<sObject> sortSObjects(List<sObject> sObjects) {
        if (!requiresPostSort) {
            return sObjects;
        }

        Integer orderBySize = orderByFields.size();
        List<sObject> sortedSObjects = new List<sObject>();
        for (Integer index = orderBySize - 1; index >= 0; index--) {
            sortedSObjects = orderByFields[index].order(sObjects);
        }

        return sortedSObjects;
    }

    public class OrderBy {
        Schema.sObjectField sObjField;
        Schema.sObjectField sObjReferenceField;
        String sortOrder;
        String nullOrder;

        public OrderBy(Schema.sObjectField sObjField) {
            this(sObjField, '');
        }

        public OrderBy(Schema.sObjectField sObjField, String sortOrder) {
            this(sObjField, sortOrder, '');
        }

        public OrderBy(Schema.sObjectField sObjField, String sortOrder, String nullOrder) {
            this.sObjField = sObjField;
            this.sortOrder = sortOrder;
            this.nullOrder = nullOrder;
        }

        public OrderBy withReferenceField(Schema.sObjectField sObjReferenceField) {
            this.sObjReferenceField = sObjReferenceField;

            return this;
        }

        public Boolean isSortable() {
            return sObjField.getDescribe().isSortable();
        }

        public override String toString() {
            String sortStatement = String.isEmpty(sortOrder) ? '' : ' ' + sortOrder;
            String nullStatement = String.isEmpty(nullOrder) ? '' : ' NULLS ' + nullOrder;

            return getOrderByField() + sortStatement + nullStatement;
        }

        public List<sObject> order(List<sObject> sObjects) {
            if (sObjField.getDescribe().isNameField()) {
                sObjects.sort();
                return sObjects;
            } else {
                Map<String, sObject> sObjectsBySortValue = new Map<String, Contact>();
                List<String> sortValues = new List<String>();
                for (sObject sObj : sObjects){
                        sObjectsBySortValue.put(sObj.get(getOrderByField()).toString(), sObj);
                        sortValues.add(sObj.get(getOrderByField()).toString());
                }
                sortValues.sort();

                Integer firstIndex = 0;
                Integer listSize = sortValues.size();
                List<sObject> sortedSObjects = new sObject[listSize - 1];

                for (Integer counter = 0; counter < listSize;  counter++){
                    Integer index = sortOrder.equalsIgnoreCase('desc') ? listSize - counter - 1 : counter;
                    sortedSObjects[index] = sObjectsBySortValue.get(sortValues[counter]);
                }
                return sortedSObjects;
            }
        }
        private String getOrderByField() {
            return sObjReferenceField == null ? 
                String.valueOf(sObjField) :
                sObjReferenceField.getDescribe().getRelationshipName() + '.' + String.valueOf(sObjField);
        }
    }
}