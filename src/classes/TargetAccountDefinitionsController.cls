public with sharing class TargetAccountDefinitionsController {
    public List<SelectOption> accountFields { get; set; }
    public List<SelectOption> operatorOptions { get; set; }
    public Map<String, String> definitionSetting { get; set; }
    public SettingWrapper newSetting { get; set; }
    public Target_Account_Def__c oldSetting { get; set; }
    public String action { get; set; }
    
    //hardcoded because i'm not sure the FuzzyMatch.ACCOUNT_FIELDS_STRING is proper for this
    public final static String SELECT_CLAUSE = 'Id';
    public final static Set<String> OPERATORS = new Set<String> {'includes', '='};
    public final static Set<String> typesThatAreQuotationEscapedInSOQL = new Set<String> {'STRING', 'PHONE'};
    
    public with sharing class SettingWrapper {
        public String fieldName { get; set; }
        public String operator { get; set; }
        public String unparsedValues { get; set; }
        public String parsedValues { get; set; }
    
        public SettingWrapper(){}
        
        public SettingWrapper(String fieldName, String operator, String unparsedValues) {
            this.fieldName = fieldName;
            this.operator = operator;
            this.unparsedValues = unparsedValues;
        }
        
        public void wrapUnparsedValues(Boolean stringField){
            parsedValues = unparsedValues;
            if (stringField && operator != 'includes') {
                parsedValues = '\'' + parsedValues + '\'';
            }
            else if (stringField && operator == 'includes') {
                List<String> pieces = parsedValues.split(',');
                String intermediate = '';
                for (Integer i = 0; i < pieces.size(); i++) {
                    if (i == pieces.size() - 1) {
                        intermediate += '\'' + pieces[i] + '\'';
                    } else {
                        intermediate += '\'' + pieces[i] + '\',';
                    }
                }
                parsedValues = '(' + intermediate + ')';
            } else if (!stringField && operator != 'includes') {
                parsedValues = '(' + parsedValues + ')';
            } else {
            //parsedValues should be the same as unparsed if not includes + not stringField
            }
        }
        
        public String wrappedSettingWhereString() {
            Map<String, String> fieldNameToType = TargetAccountDefinitionsController.generateApiToType();
            String fieldType = fieldNameToType.get(fieldName);
            Boolean stringField = (typesThatAreQuotationEscapedInSOQL.contains(fieldType));
            String whereString = String.valueOf(fieldName) + ' ' + String.valueOf(operator) + ' ';
            wrapUnparsedValues(stringField);
            whereString += parsedValues;
            //if (operator == 'includes') {
              //  whereString += '(' + unparsedValues + ')';
            //} else {
              //  whereString += unparsedValues;
                //whereString += '\'' + unparsedValues + '\'';
            //}
        
            return whereString;
        }
    }
    
    public void saveNewSettingFromWrapper() {
        //naive version
        Target_Account_Def__c targetAccountSettingRecord;
        if (oldSetting == null) {        
            targetAccountSettingRecord = new Target_Account_Def__c(name = String.valueOf(DateTime.now()) ,account_field__c = newSetting.fieldName,
                operator__c = newSetting.operator,
                values__c = newSetting.parsedValues,
                unparsed_values__c = newSetting.unparsedValues 
           );
       } else {
           targetAccountSettingRecord = oldSetting;
           oldSetting.operator__c = newSetting.operator;
           oldSetting.values__c = newSetting.parsedValues;
           oldSetting.unparsed_values__c = newSetting.unparsedValues;
           oldSetting.name =  String.valueOf(DateTime.now());
           oldSetting.account_field__c = newSetting.fieldName;
       }
       upsert(targetAccountSettingRecord);
    }
    
    public TargetAccountDefinitionsController(){
        SObjectType accountType = Schema.getGlobalDescribe().get('Account');
        Map<String,Schema.SObjectField> accountFieldMap = accountType.getDescribe().fields.getMap();
        Set<String> fields = accountFieldMap.keySet();
        this.accountFields = TargetAccountDefinitionsController.generateSelectList(fields, accountFieldMap);
        this.operatorOptions = TargetAccountDefinitionsController.generateSelectList(TargetAccountDefinitionsController.OPERATORS);
        Target_Account_Def__c singletonDefinition = [SELECT name, operator__c, unparsed_Values__c, Id, account_field__c, values__c FROM Target_Account_Def__c LIMIT 1];
        if (singletonDefinition != null) {
            this.oldSetting = singletonDefinition;
            this.action = 'Update Active Account Definition';
            this.newSetting = new SettingWrapper(singletonDefinition.account_field__c, singletonDefinition.operator__c, singletonDefinition.unparsed_Values__c);
        } else {
            this.action = 'Create Active Account Definition';
            this.newSetting = new SettingWrapper();
        }
        
    }
    
    
    public static List<SelectOption> generateSelectList(Set<String> optionLabels) {
        List<SelectOption> selectList = new List<SelectOption>();
        for (String selectItem : optionLabels) {
            SelectOption nextItem = new SelectOption(selectItem, selectItem);
            selectList.add(nextItem);
        }
        return selectList;
    }
    
    public static List<SelectOption> generateSelectList(Set<String> optionLabels,Map<String, Schema.SObjectField> fieldMap) {
        List<SelectOption> selectList = new List<SelectOption>();
        for (String selectItem : optionLabels) {
            String label = fieldMap.get(selectItem).getDescribe().getLabel();
            SelectOption nextItem = new SelectOption(selectItem, label);
            selectList.add(nextItem);
        }
        return selectList;
    }
    
    
    
    
    public void validateNewSetting() {
        String whereString = newSetting.wrappedSettingWhereString();
        try {
            List<SObject> queriedAccounts = queryAccounts(whereString);
            String message = String.valueOf(queriedAccounts.size()) + ' accounts found where ' + whereString;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, message));           
        } catch (Exception x) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, x.getMessage()));           
        }
    
    }
    
    public static Map<String,String> generateApiToType() {
        Map<String, String> apiSObjectFieldMap = new Map<String, String>();
        Map<String, Schema.SObjectField> objectFieldMap = Schema.SObjectType.Account.fields.getMap();
        List<Schema.SObjectField> objectFields = objectFieldMap.values();
        for(Schema.SObjectField s : objectFields) {
            apiSObjectFieldMap.put(s.getDescribe().getName().toLowerCase(), String.valueOf(s.getDescribe().getType()));
        }
        return apiSObjectFieldMap;
    }  
    
    //not sure about the final form this should take
    //do we really wanna build up a grand string and do SOQL each time?
    //will create when gain access to LD class
    public static String buildWhereString() {
        
        String whereString = '';
        return whereString;
    }
    
    public static List<SObject> getTargetAccounts() {
        return queryAccounts(buildWhereString());
    }
    
    public static List<SObject> queryAccounts(String whereString) {
        String query = 'SELECT ' + SELECT_CLAUSE + ' FROM Account WHERE ' + whereString;
        List<SObject> queriedAccounts = Database.query(query);
        return queriedAccounts;
    }
    
    
}