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
    private UTIL_OrderBy orderBy;

    /*******************************************************************************************************************
    * @description UTIL_Finder constructor for the provided sObject Type
    */
    public UTIL_Finder(sObjectType sObjType) {
        this.sObjType = sObjType;
        this.orderBy = new UTIL_OrderBy();
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with all passed in select fields
    */
    public UTIL_Finder withSelectFields(Set<Schema.sObjectField> sObjFields, Schema.SObjectField referenceField) {
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
            orderBy.add(new UTIL_OrderBy.FieldExpression(sObjField));
        }

        return this;
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with passed in order by field
    */
    public UTIL_Finder withOrderBy(UTIL_OrderBy.FieldExpression field) {
        orderBy.add(field);

        return this;
    }

    /*******************************************************************************************************************
    * @description Returns all sObjects for this sObject Type
    */
    public List<sObject> findAll() {
        List<sObject> sObjects = Database.query(buildQuery());

        return orderBy.sort(sObjects);
    }

    /*******************************************************************************************************************
    * @description Returns all sObjects for this sObject Type
    */
    public List<sObject> findByRelatedToIds(Schema.sObjectField referenceField, Set<Id> relatedToIds) {
        condition = String.valueOf(referenceField) + ' IN :relatedToIds';
        List<sObject> sObjects = Database.query(buildQuery());

        return orderBy.sort(sObjects);
    }

    private String buildQuery() {
        String query = new UTIL_Query()
                .withFrom(sObjType)
                .withSelectFields(selectFields)
                .withWhere(condition)
                .withOrderBy(orderBy.build())
                .build();

        return query;
    }

}