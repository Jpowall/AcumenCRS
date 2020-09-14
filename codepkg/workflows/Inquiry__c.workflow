<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Technical_Assistance_on_Site_Visit_Updat</fullName>
        <description>Any site visit = technical assistance</description>
        <field>Technical_Assistance__c</field>
        <literalValue>1</literalValue>
        <name>Technical Assistance on Site Visit Updat</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Site Visit %3D Technical Assistance</fullName>
        <actions>
            <name>Technical_Assistance_on_Site_Visit_Updat</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Inquiry__c.Site_Visit__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
