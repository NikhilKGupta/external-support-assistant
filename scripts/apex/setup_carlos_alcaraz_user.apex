// Step 2 of 2: Create Experience Site User + Permission Set Assignments
// Requires Contact ID from setup_carlos_alcaraz_records.apex step 1.
// Run: sf apex run --file scripts/apex/setup_carlos_alcaraz_user.apex -o dhurandhar

Id contactId = null; // populated below from step 1 output
// Look up the Contact created in step 1
Contact c = [SELECT Id FROM Contact WHERE Email = 'nikhilgupta+carlosalcaraznike@salesforce.com' LIMIT 1];
contactId = c.Id;

Profile p = [SELECT Id FROM Profile WHERE Name = 'SDO-Customer Community Plus' LIMIT 1];

User u = new User(
    FirstName         = 'Carlos',
    LastName          = 'Alcaraz',
    Email             = 'nikhilgupta+carlosalcaraznike@salesforce.com',
    Username          = 'nikhilgupta+carlosalcaraznike@salesforce.com',
    Alias             = 'calcaraz',
    CommunityNickname = 'carlosalcaraz',
    TimeZoneSidKey    = 'America/Los_Angeles',
    LocaleSidKey      = 'en_US',
    EmailEncodingKey  = 'UTF-8',
    LanguageLocaleKey = 'en_US',
    ProfileId         = p.Id,
    ContactId         = contactId
);
insert u;
System.debug('### User: ' + u.Id);

// Workday_Risk_Monitor_Access (0PSHu00000ByF05OAF) grants viewAllRecords on Account/Case,
// which is incompatible with the PowerCustomerSuccess external license.
// External portal users get only Workday_Support_Agent_Access.
insert new PermissionSetAssignment(
    AssigneeId      = u.Id,
    PermissionSetId = '0PSHu00000ByF06OAF'  // Workday_Support_Agent_Access
);
System.debug('### Permission sets assigned');
System.debug('### Setup complete — User: ' + u.Id);
