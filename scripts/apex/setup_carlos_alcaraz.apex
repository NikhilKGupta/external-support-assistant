// Carlos Alcaraz (Nike) — Experience Site user setup for dhurandhar org
// Portal: Workday Resource Center (customers)
// Profile: Customer Community Plus Login User (00eHu000004neMsIAI)
// Run: sf apex run --file scripts/apex/setup_carlos_alcaraz.apex -o dhurandhar

// 1. Account (Nike)
Account acct = new Account(Name = 'Nike');
insert acct;
System.debug('Account created: ' + acct.Id);

// 2. Contact — linked to portal user
Contact c = new Contact(
    FirstName   = 'Carlos',
    LastName    = 'Alcaraz',
    Email       = 'nikhilgupta+carlosalcaraznike@salesforce.com',
    AccountId   = acct.Id,
    Department  = 'HCM Administration',
    Title       = 'Workday Administrator'
);
insert c;
System.debug('Contact created: ' + c.Id);

// 3. Experience Site user
// Using 'SDO-Customer Community Plus' (custom profile, same Customer Community Plus license)
// to avoid the "standard external profile" Setup flag requirement.
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
    ContactId         = c.Id
);
insert u;
System.debug('User created: ' + u.Id);

// 4. Permission set assignments
List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>{
    new PermissionSetAssignment(
        AssigneeId      = u.Id,
        PermissionSetId = '0PSHu00000ByF06OAF'  // Workday_Support_Agent_Access
    ),
    new PermissionSetAssignment(
        AssigneeId      = u.Id,
        PermissionSetId = '0PSHu00000ByF05OAF'  // Workday_Risk_Monitor_Access
    )
};
insert psas;
System.debug('Permission sets assigned: ' + psas.size());
System.debug('Done — Account: ' + acct.Id + ' | Contact: ' + c.Id + ' | User: ' + u.Id);
